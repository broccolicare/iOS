# iOS Integration Guide — Broccoli AI Backend

How an iOS client talks to this service to run the **Health Chatbot** and the
**Pre-appointment Intake** conversations.

This is a thin, stateless HTTP service. It does **not** own users, appointments,
or login — Laravel does. The iOS app authenticates against Laravel as it already
does, then presents that same token to this service. Every conversational turn is
**streamed** back over Server-Sent Events (SSE); there is no "send message, get
one JSON reply" endpoint.

---

## 1. The mental model (read this first)

```
┌────────────┐   Sanctum token    ┌────────────┐
│            │ ──────────────────▶│   Laravel  │   (login, appointments, users)
│  iOS app   │ ◀───── token ──────│            │
│            │                    └────────────┘
│            │   Bearer <token>   ┌──────────────────┐
│            │ ──────────────────▶│  AI backend      │   (this service)
│            │ ◀═══ SSE stream ═══│  /chatbot/turn   │
└────────────┘                    │  /intake/turn    │
                                  └──────────────────┘
```

Key facts the client must internalise:

1. **The server owns conversation history.** The client sends **only the next
   message** (plus a `conversation_id` to continue a thread). Never send prior
   turns — the server loads the authoritative transcript from its own database
   and ignores any history the client might try to supply.
2. **Responses are streamed as SSE**, not a single JSON body. The reply arrives as
   a sequence of events (`token`, `tool_result`, `done`).
3. **The same token you use for Laravel is the token you use here.** No separate
   login. (See §3 — the backend runs in "Sanctum bridge" mode.)
4. **Identity comes from the token, never the request body.** The patient id is
   read from the verified token. There is no `patient_id` field to send, and
   trying to act on another patient's `conversation_id` returns `404`.

---

## 2. Base URL & environments

| Environment | Base URL |
|-------------|----------|
| Local dev   | `http://127.0.0.1:8000` |
| Staging     | `https://aiapp.broccolicare.ie` — **current integration target** |
| Production  | `https://aiapp.broccolicare.ie` — ⚠️ **placeholder: same host as staging** |

> ### ⚠️ The hostname is `aiapp` — singular
>
> **`aiapps.broccolicare.ie` (plural) does not exist.** It is not a configured
> `server_name` and does not even resolve in DNS. Verified 2026-07-20:
>
> ```
> aiapps.broccolicare.ie  → curl: (6) Could not resolve host
> aiapp.broccolicare.ie   → HTTP 200  {"status":"ok","version":"0.0.0"}
> ```
>
> If an earlier build config used `aiapps`, correct it in **both** staging and
> production configurations.

> **⚠️ Production currently points at the staging host** as a temporary placeholder so
> both build configurations resolve. A dedicated production host must be issued before
> any public release — see `ios-integration-questions.md` Q4.
>
> **Until infra confirms staging is backed by a separate Laravel instance and
> database, assume staging may touch production data — use synthetic records only.**

Make the base URL a build-configuration value (scheme / xcconfig) rather than a
hard-coded constant, so the real production host can be dropped in without a code
change when it's issued.

All paths below are relative to the base URL. Use HTTPS everywhere except a
developer's own machine.

**Quick reachability checks (no auth required):**

| Method & path | Purpose | Success |
|---------------|---------|---------|
| `GET /health` | Liveness — "is the process up?" | `200 {"status":"ok","version":"…"}` |
| `GET /ready`  | Readiness — DB (and vector store) reachable | `200 {"status":"ready", …}` / `503` if a dependency is down |

Use `/health` for a lightweight connectivity probe. You do **not** need to poll
`/ready` from the app — it's for infra/monitoring.

---

## 3. Authentication

Send the user's token on every call to a protected endpoint:

```
Authorization: Bearer <token>
```

Where `<token>` is the **Laravel Sanctum personal-access token** — the same
`"{id}|{plaintext}"` string Laravel already issues to the app on login. The
backend currently runs in `AUTH_MODE=sanctum_db`, meaning it validates that
Sanctum token directly against the shared database. **You do not do anything
special for this service** — reuse the token you already hold.

> **Forward-compatibility:** the backend is designed to switch to Laravel-minted
> JWTs later (`AUTH_MODE=jwt`) with no change to any endpoint or request shape.
> When that happens you'll simply be handed a JWT instead of a Sanctum token and
> put it in the exact same `Authorization: Bearer` header. Build your networking
> layer so the token is an opaque string — don't parse or depend on its format.

**Auth failures** — a missing, malformed, expired, or revoked token returns a
uniform `401` (the server deliberately gives the same response for every auth
failure mode, so you can't distinguish "expired" from "invalid"):

```json
{ "error": { "code": "unauthorized",
             "message": "Invalid authentication credentials.",
             "correlation_id": "…" } }
```

On `401`, treat the session as invalid: re-authenticate against Laravel to obtain
a fresh token, then retry.

---

## 4. The chat turn — `POST /chatbot/turn`

One conversational turn. Streams the assistant's reply as SSE.

### Request

```
POST /chatbot/turn
Authorization: Bearer <token>
Content-Type: application/json
Accept: text/event-stream
```

```jsonc
{
  "message": "I've had a sore throat for three days, should I be worried?",
  "conversation_id": 12   // OMIT to start a new conversation; include to continue one
}
```

| Field | Type | Rules |
|-------|------|-------|
| `message` | string | **required**, 1–8000 chars |
| `conversation_id` | int | optional. Omit → new conversation. Include → resume that thread (must belong to this patient, else `404`). |

That's the entire request. No history, no patient id, no role.

### Conversation lifecycle

- **First message of a chat:** omit `conversation_id`. The server creates a new
  conversation and returns its id in the `done` event (see below).
- **Every subsequent message:** send the `conversation_id` you received. Hold it
  **in memory only**, for the life of the session — see §4.2.
- Starting an intake/chat is cheap; there's no separate "create conversation"
  call — the first turn creates it.

### Response — the SSE stream

`Content-Type: text/event-stream`. Events arrive in this order:

```
event: tool_result
data: {"tool": "lookup_appointments", "data": {"appointments": [ … ]}}

event: token
data: {"text": "You"}

event: token
data: {"text": " should"}

event: token
data: {"text": " rest and hydrate…"}

event: done
data: {"status": "ok", "conversation_id": 12, "conversation_status": null, "error_code": null}
```

| Event | When | Payload | What the client does |
|-------|------|---------|----------------------|
| `tool_result` | zero or more, **before** the text | `{"tool": "<name>", "data": {…}}` | Render an inline **card**. The `data` shape depends on `tool` — see §4.1. **Silently ignore tool names you don't recognise** (the server may add tools without a client release). |
| `token` | zero or more, in order | `{"text": "…"}` | Append `text` to the message bubble as it streams. Concatenate in arrival order. |
| `done` | **exactly one, last** | see below | Finalise the turn. Read `conversation_id` and save it. |

**The `done` event** is the source of truth for the turn's outcome:

```jsonc
{
  "status": "ok",                 // "ok" | "error" | "guardrail_blocked"
  "conversation_id": 12,          // ALWAYS present — save it
  "conversation_status": null,    // null | "completed" | "emergency_signposted"
  "error_code": null              // a machine code string when status == "error"
}
```

`status` — handle **all three** values:

| `status` | Meaning | Client action |
|----------|---------|---------------|
| `"ok"` | Normal successful turn | Render the reply. |
| `"error"` | The turn failed inside the engine (e.g. the AI provider was unavailable) | You'll usually still receive a graceful fallback message in `token` events; show it and offer retry. `error_code` carries the machine-readable reason. |
| `"guardrail_blocked"` | A safety guardrail fired | Accompanies `conversation_status == "emergency_signposted"` (see §5). Surface the signpost text prominently; do not auto-continue. |

`conversation_status` — `null` on a normal ongoing turn, `"completed"` when an
intake questionnaire finishes, `"emergency_signposted"` when a red-flag safety
guardrail fires. **`emergency_signposted` can occur on both chatbot and intake.**

- Always read `conversation_id` from `done` and store it — this is how you get the
  id for a brand-new conversation.

> **Important — process-then-stream, and what it costs you:** the server runs the
> *entire* turn (AI call, safety guardrails, persistence, audit) to completion
> **before** the stream starts flowing. Consequences:
> - The socket is **completely silent — zero bytes, no keepalive/`: ping`** — from
>   the POST until the turn is fully done, then all events arrive in a rapid burst.
>   This is **not** an incremental typewriter effect; show a single spinner until
>   the burst arrives.
> - **Set the client request timeout to ~120s.** A worst-case turn (up to 5 tool
>   iterations × 30s AI timeout × retries) can run into the low minutes. There is no
>   intermediate byte to reset an idle timer, so the read timeout must cover the
>   whole worst case. The 60s default **will** cut off legitimate turns.

> **⚠️ A dropped connection mid-stream: do NOT auto-retry.** The turn is already
> committed server-side, so server state is safe — but there is **no idempotency key
> and no server-side dedupe**. Re-POSTing the same `message` starts a **second**
> turn: a second AI reply and a second pair of stored messages. There is also no
> transcript read endpoint (see §4.2), so a reply lost mid-stream **cannot be
> recovered**. Treat a drop as *"the turn may have succeeded"*: surface a **manual**
> retry affordance and let the user decide.

### 4.1 Tool-result payloads

The `tool` field is the tool's internal name, streamed verbatim.

**Chatbot (`/chatbot/turn`):**

| `tool` | `data` shape | Notes |
|--------|--------------|-------|
| `lookup_appointments` | `{"appointments": [{"id": int, "specialty": string, "scheduled_at": ISO-8601 string, "status": string}]}` | List may be empty. ⚠️ See the timezone warning below. |
| `create_medication_reminder` | `{"id": int, "status": string}` | Confirmation of a created reminder. ⚠️ Create-only — see below. |
| `prepare_booking` | See §4.1.1 | **Prefills our existing native booking flow.** Does not book. Stable — build against this. |
| ~~`start_booking`~~ | — | 🛑 **Deprecated — do NOT write a handler.** Still registered only so chat booking keeps working until our `prepare_booking` handler ships; removed the release after. Ignoring it is safe under the unknown-tool rule. |

**Intake (`/intake/turn`):**

| `tool` | `data` shape | Notes |
|--------|--------------|-------|
| `offer_quick_replies` | `{"options": [string, string, …]}` | 2–6 plain strings, each ≤ 60 chars. See §5. |

**The two surfaces have disjoint tool sets — there is no overlap.**
`offer_quick_replies` is **intake-exclusive**; build the quick-reply button UI on the
intake surface only. The booking/appointment/reminder tools are chatbot-only.

⚠️ **`lookup_appointments[].status` and `.specialty`, and
`create_medication_reminder.status`, are free text — not enums.** They are forwarded
from Laravel verbatim with no validation. Values seen in fixtures (`"confirmed"`,
`"scheduled"`) are illustrative, **not a contract**. Do not `switch` exhaustively on
them; always have a default branch.

⚠️ **`scheduled_at` has no timezone normalisation — do not display it yet.** The
backend parses and re-serialises whatever Laravel sends. If Laravel sends a naive
timestamp, there is **nothing in the payload indicating its zone**, and Ireland
observes DST. Showing a wrong appointment time is a real clinical-safety issue.
Confirm the zone with the Laravel team before rendering these. (Backend has proposed
normalising to UTC-with-offset — pending.)

⚠️ **Medication reminders are create-only.** This service has no list, cancel, update,
or delete endpoint for reminders. A reminder created via chat **cannot be viewed or
cancelled through this API at all**. Do not build a "manage reminders" affordance
against it, and word the confirmation card so it doesn't imply in-app management.

`complete_intake` is a model-internal marker — it emits **no** `tool_result` event.
Learn that intake finished from `done.conversation_status == "completed"` only.

> **Decoders must tolerate unknown/extra fields.** The Laravel-backed shapes
> (`lookup_appointments`, `create_medication_reminder`) mirror Laravel's S2S responses
> and are **provisional** — Laravel may add fields. Swift's `JSONDecoder` ignores
> unknown keys by default, so this is satisfied as long as you don't write a strict
> custom `init(from:)`. **`prepare_booking` and `offer_quick_replies` are exempt** —
> both shapes are owned entirely by this service and are stable.

### 4.1.1 `prepare_booking` — the booking card

Replaces the old `start_booking` browser redirect. It makes **no network call** — pure
local mapping — so booking from chat keeps working through a Laravel outage. Chat
produces booking *parameters*; our existing native flow runs unchanged.

```json
{ "tool": "prepare_booking",
  "data": { "action": "open_booking", "department_id": 4, "is_gp": false,
            "service_hint": "full blood count", "service_id": null,
            "date_from": "2026-07-27", "date_to": "2026-08-03",
            "time_preference": "morning",
            "reason": "Follow-up bloods requested by GP",
            "display": { "title": "Blood test",
                         "subtitle": "Mornings, week of 27 July",
                         "cta": "Choose a time" } } }
```

| Field | Type | Guarantee |
|-------|------|-----------|
| `action` | string | `"open_booking"` today. **Unknown value → ignore the card.** |
| `department_id` | int | Always present. 1 GP · 2 specialist · 3 nutritionist · 4 blood test |
| `is_gp` | bool | Always present. Mirrors our `isGP` `"1"`/`"0"` |
| `service_hint` | string \| null | Free text for us to resolve |
| `service_id` | int \| null | Key always present, **value always `null` today** |
| `date_from` / `date_to` | ISO date \| null | A *window*, not a commitment |
| `time_preference` | enum \| null | `morning`/`afternoon`/`evening`/`any` |
| `reason` | string \| null | Patient's own words |
| `display` | object | Always present. `title`/`cta` non-null; `subtitle` may be null |

**Only `action`, `department_id`, `is_gp` and `display` are guaranteed non-null —
decode everything else as optional.**

Three behaviours to build against:

1. **`service_id` is always `null` today but the key is always present.** Write the
   rule now — *if `service_id` is non-null use it, otherwise resolve `service_hint`* —
   and we need **no release** when the server starts populating it.
2. **Impossible date windows are already stripped server-side.** A past `date_from` is
   dropped, and both are dropped if `date_to < date_from`. You'll never get a
   nonsensical window, but you *will* get `null` — keep the "open on the form's
   default" path.
3. **`reason` may be `null` even when the patient clearly gave one.** It is dropped if
   it reads as a clinical interpretation ("possible meniscus tear") rather than a
   description ("knee pain following a fall") — a diagnosis must not reach a
   clinician's record via chat. **The card always ships regardless; only the field
   goes.** Never treat a null `reason` as an error or an empty card.

**Integration:** prefill `BookingGlobalViewModel` and push the existing form. If
`service_hint` doesn't resolve, push `SpecialtyListView` — the user lands where they'd
have been anyway. Chat only saves taps; it must never dead-end.

> **⚠️ Constraint: never route past `BookingConfirmationView`.** When `initialize`
> returns `covered: true` (subscription pays) Stripe is skipped, making that screen the
> only human checkpoint before a real appointment is created.

### 4.2 Session persistence — chatbot ephemeral, intake resumable

**Product decision — the two surfaces differ. This is deliberate.**

| Surface | Persistence | Rule |
|---------|-------------|------|
| **Chatbot** | **Ephemeral** | Never write `conversation_id` to disk. Hold in memory for the session; discard on exit. Re-entering chat always starts a **new** conversation. |
| **Intake** | **Persisted** | Store the intake `conversation_id` **scoped to its `appointment_id`** and resume it on re-entry. |

**Why intake is exempt.** Intake is a structured multi-question clinical interview. A
patient interrupted at question 8 who must restart at question 1 will frequently
abandon it — and an abandoned intake produces **no summary at all**, so the failure
mode is a *lost clinical record*, not just a lost transcript. Restart-on-reentry also
lets a second, thinner intake silently supersede a richer first one in the doctor's
view (the doctor-prep screen reads the most recently inserted summary). Summary quality
does not suffer from resuming: the model only keeps the last 20 messages as working
context, but the **final summary is generated from the entire transcript**, so a longer
resumed intake yields a *better* summary.

**So, concretely:**

- Persist **only** the intake `conversation_id`, keyed by `appointment_id`. Nothing else.
- Chatbot stays fully ephemeral — no change to the privacy posture where it matters.
- Discard a stored intake id once `conversation_status == "completed"`, and fall back
  to starting fresh if a stored id ever `404`s.

**No read endpoint exists either way.** This service exposes only
`POST /chatbot/turn`, `POST /intake/turn`, `GET /health`, `GET /ready`. Resuming means
sending the `conversation_id` on the next turn — you still cannot fetch prior turns, so
the *displayed* intake transcript restarts empty even when the server-side thread
continues. Consider a "picking up where you left off" affordance.

**Session end is a client-side concept only** — there is no "end session" call and the
server keeps conversations resumable indefinitely. The client just stops referencing
the id.

The remaining edge case: a **connection drop mid-turn**. The reply is lost from the
client and cannot be re-fetched, and re-POSTing would duplicate the turn (§4). Offer
manual retry.

### 4.3 One turn in flight per conversation

There is **no server-side lock**. Two concurrent turns on the same
`conversation_id` will both run, both write, and can interleave into a corrupted
transcript. **The client must serialise:** disable the input and send button from
the moment you POST until you receive `done`.

---

## 5. The intake turn — `POST /intake/turn`

The pre-appointment questionnaire. Same engine, same SSE protocol as the chatbot,
with two differences: it's tied to an **appointment**, and it **completes**.

### Request

```
POST /intake/turn
Authorization: Bearer <token>
Content-Type: application/json
Accept: text/event-stream
```

```jsonc
{
  "message": "It's a persistent cough.",
  "conversation_id": 34,     // omit on the FIRST turn, include to resume
  "appointment_id": 501      // REQUIRED on the first turn; ignored when resuming
}
```

| Field | Type | Rules |
|-------|------|-------|
| `message` | string | required, 1–8000 chars |
| `conversation_id` | int | omit to start, include to resume |
| `appointment_id` | int | **required to start** an intake (omit → `422`). Must be an appointment this patient owns (else `404`). Ignored on resume — a resumed intake keeps the appointment it started against. |

### Adaptive questions & quick replies

There is **no fixed question list**. The assistant decides the next question from
the answers so far. The client's whole job each turn is to send the user's next
message.

The assistant may offer **quick-reply buttons** — these arrive as a `tool_result`
event with `tool: "offer_quick_replies"` and a payload of **plain strings**, not
objects:

```json
{ "tool": "offer_quick_replies", "data": { "options": ["Yes", "No", "Not sure"] } }
```

There is no separate label/value — the string *is* both. Render each as a tappable
button and, when tapped, **send that exact string back as the next `message`**.

**Keep the text input enabled alongside the buttons.** The server does not
constrain the next `message` to the offered options; the model handles free text
equally well. The buttons are a convenience, not a mode.

### Completion

When the questionnaire is finished, the final `done` event carries:

```jsonc
{ "status": "ok", "conversation_id": 34,
  "conversation_status": "completed", "error_code": null }
```

On `conversation_status == "completed"`, **stop showing the input box** — the
intake is over. The structured summary has been written server-side against the
appointment (the doctor reads it later; the app does not need to fetch it).

### Emergency signposting

If a red-flag safety guardrail fires, `done` carries `status: "guardrail_blocked"`
and `conversation_status: "emergency_signposted"`:

```jsonc
{ "status": "guardrail_blocked", "conversation_id": 34,
  "conversation_status": "emergency_signposted", "error_code": null }
```

This can happen on **both** `/chatbot/turn` and `/intake/turn`. The `token` events
carry approved text signposting the user to emergency care — always streamed (§6.2).

> **⚠️ The server does NOT enforce a close — the client must.** The status is written,
> but **nothing reads it back to gate a later turn**; only ownership is checked on
> resume. The user can send another message on the same `conversation_id` immediately
> and it is evaluated from scratch with no memory of the signpost. There is no
> lockout, cooldown, or per-patient rate limit anywhere. **If we want the thread
> closed, we disable the composer on
> `conversation_status == "emergency_signposted"` ourselves.**

**A signposted intake never produces a summary.** The finalisation path explicitly
refuses to write one for a signposted conversation. That's deliberate and clinically
correct, but it means the appointment ends up with **no intake summary at all** — the
doctor-prep screen will be empty.

**No emergency number is emitted.** The signpost text says only "your local emergency
services." Nothing is region-aware.

**Product decision — our behaviour on `emergency_signposted`:**

1. **Close the composer.** Disable the input for that thread. The server won't do it,
   so we enforce it client-side. No backend dependency — we can ship this now.
2. **Surface a native `tel:` affordance for 112.** EU-wide and works alongside 999 in
   Ireland. Show it prominently alongside the signpost text.

> **⚠️ Pending clinical sign-off.** Detection is **keyword-only** (the classifier layer
> is unwired) and the term list is marked in backend code as **not clinically signed
> off** — expect both false positives and misses. Since a false positive now hard-closes
> the thread and shows an emergency number, this UI must not ship before that sign-off.

> **⚠️ Detection quality:** red-flag detection is **keyword-only** (the classifier
> layer is unwired), and the term list is marked in backend code as **not clinically
> signed off**. Expect both false positives and misses. Weight the UX accordingly — and
> note this needs clinical sign-off before release.

### Conversation expiry

Conversations do **not** auto-expire on inactivity server-side. This is mostly moot
for us: sessions are ephemeral (§4.2), so we never resume a `conversation_id` across
sessions and a stale id is never sent. Within a live session, ids stay valid.

---

## 6. Error handling

Non-streaming errors (auth, validation, ownership) come back as a normal JSON body
with this stable envelope — **not** as an SSE stream:

```jsonc
{ "error": {
    "code": "not_found",              // stable machine code (snake_case)
    "message": "Conversation not found.",
    "correlation_id": "3f9c…"         // include this when reporting a bug
} }
```

| HTTP | `code` | Cause | Client action |
|------|--------|-------|---------------|
| `401` | `unauthorized` | Missing/expired/invalid token | Re-authenticate with Laravel, retry |
| `404` | `not_found` | `conversation_id` / `appointment_id` not owned by this patient, or doesn't exist | Don't retry as-is; start fresh |
| `422` | `unprocessable_entity` | Body failed validation (empty `message`, missing `appointment_id` on intake start, etc.) | Fix the request; a `details` array pinpoints the field |
| `429` | `rate_limited` | Per-user rate limit. **Not emitted today** — infra may enable it in production | Code for it now: honour `Retry-After` if present, else exponential backoff |
| `503` | `service_unavailable` | A dependency (e.g. Laravel appointment check) is down | Show "try again shortly", retry with backoff |
| `500` | `internal_error` | Unexpected server error | Show generic error; report the `correlation_id` |

**Distinguishing an error from a stream:** check the response `Content-Type`
before parsing. `text/event-stream` → consume as SSE (§4). `application/json` →
parse the error envelope above. A non-2xx status always means the JSON envelope.

**Two ways a turn can "fail":**
1. **HTTP-level** (before streaming) — 4xx/5xx JSON envelope, above.
2. **Turn-level** (during streaming) — HTTP `200`, an SSE stream whose `done`
   event has `status: "error"` and a non-null `error_code`. Handle both.

Note the asymmetry: **auth and routing failures arrive as HTTP status codes before any
stream opens**; only in-turn failures arrive as `done.error_code`. Both paths are
needed. (`400 bad_request` also exists — token subject isn't a patient id.)

### 6.1 `error_code` — the complete list

Five strings plus `null`. Nothing else can appear.

| `error_code` | `done.status` | Trigger | Retry? |
|---|---|---|---|
| `null` | `ok` | Normal completion | n/a |
| `provider_error` | `error` | Any provider failure — timeout, connection error, rate limit, 5xx after internal retries, **and open circuit breaker** | ✅ **Only retryable code** |
| `input_moderation` | `guardrail_blocked` | Moderation flagged the user's text, pre-generation | ❌ Terminal |
| `red_flag_keyword` | `guardrail_blocked` | Emergency term matched → also sets `conversation_status: "emergency_signposted"` | ❌ Terminal |
| `red_flag_classifier` | `guardrail_blocked` | Classifier layer — **not wired today**, won't appear in testing | ❌ Terminal |
| `output_moderation` | `guardrail_blocked` | Answer classified as diagnosis/prescription/advice, post-generation | ❌ Terminal |

**`provider_error` is the only retryable code** — everything else is content-based, so
re-sending the same text reproduces it. Retrying a terminal code is pure waste.

> **⚠️ Circuit breaker and retry timing.** An open circuit surfaces as
> `provider_error`, **indistinguishable from an ordinary provider failure**, with no
> distinct code and no `Retry-After`. The breaker's reset defaults to **30s**, so a
> client retrying sooner just fails fast again. **Use exponential backoff starting
> ≥ 30s, max 2–3 attempts.** Prefer a manual retry affordance over an automatic one —
> there's no idempotency, so an auto-retry can double-post the turn (§4).

**Never appears in `done`:** `unknown_tool`, `invalid_arguments`, `tool_failed`. These
are tool-execution failures fed back to the *model* as tool results; they stay inside
the transcript and the turn can still finish `status: "ok"`. Don't map them.

### 6.2 `guardrail_blocked` always streams text

**You never need your own fallback copy.** On every `guardrail_blocked` path — input-
and output-phase — at least one `token` event carrying approved signpost text arrives
**before** `done`. Even `provider_error` streams a token. A token event is guaranteed
on every terminal status, not just success. Render what you receive.

> **⚠️ An output-phase block drops that turn's tool cards.** Guardrails run
> post-generation as well as pre-generation. When the output is blocked, the deflection
> text **replaces** the answer and any `tool_result` cards already emitted in that turn
> are dropped. **Don't assume a card you rendered mid-turn survives to `done`** — be
> ready to clear it.

---

## 7. Request headers reference

| Header | Value | Notes |
|--------|-------|-------|
| `Authorization` | `Bearer <token>` | Required on `/chatbot/turn`, `/intake/turn` |
| `Content-Type` | `application/json` | On the POST body |
| `Accept` | `text/event-stream` | Signals you want the stream |
| `X-Correlation-ID` | *(optional)* a UUID you generate | Echoed back in the response header and stamped on all server logs for this request. Set it to make support/debugging traceable end-to-end. If you omit it, the server generates one. |

Whatever `X-Correlation-ID` you send (or the server generates) is also present in
error envelopes and response headers — log it on the client so a user-reported
issue can be matched to server logs.

---

## 8. Swift reference implementation (SSE)

`URLSession`'s async `bytes(for:)` API streams the body line-by-line — ideal for
SSE. No third-party library needed.

```swift
struct TurnDone: Decodable {
    let status: String
    let conversationId: Int
    let conversationStatus: String?
    let errorCode: String?
    enum CodingKeys: String, CodingKey {
        case status
        case conversationId = "conversation_id"
        case conversationStatus = "conversation_status"
        case errorCode = "error_code"
    }
}

enum TurnEvent {
    case token(String)                       // append to the bubble
    case toolResult(tool: String, data: Data) // render an inline card
    case done(TurnDone)                       // finalise; save conversationId
}

func streamChatTurn(
    baseURL: URL,
    token: String,
    message: String,
    conversationId: Int?,
    onEvent: @escaping (TurnEvent) -> Void
) async throws {
    var req = URLRequest(url: baseURL.appendingPathComponent("/chatbot/turn"))
    req.httpMethod = "POST"
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("text/event-stream", forHTTPHeaderField: "Accept")
    // The socket stays silent for the whole turn (no keepalive) — the timeout must
    // cover the full worst-case turn duration, not just time-to-first-byte.
    req.timeoutInterval = 120

    var body: [String: Any] = ["message": message]
    if let id = conversationId { body["conversation_id"] = id }
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, response) = try await URLSession.shared.bytes(for: req)
    guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }

    // Non-streaming error: body is a JSON error envelope, not SSE.
    guard http.statusCode == 200 else {
        // Read the small JSON body and surface error.code / error.message.
        throw APIError(statusCode: http.statusCode)
    }

    // Minimal SSE parser: accumulate `event:` and `data:` lines until a blank line.
    var eventName = ""
    var dataBuffer = ""

    func flush() {
        guard !dataBuffer.isEmpty else { return }
        let json = Data(dataBuffer.utf8)
        switch eventName {
        case "token":
            if let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
               let text = obj["text"] as? String {
                onEvent(.token(text))
            }
        case "tool_result":
            if let obj = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
               let tool = obj["tool"] as? String,
               let inner = obj["data"],
               let innerData = try? JSONSerialization.data(withJSONObject: inner) {
                onEvent(.toolResult(tool: tool, data: innerData))
            }
        case "done":
            if let done = try? JSONDecoder().decode(TurnDone.self, from: json) {
                onEvent(.done(done))
            }
        default:
            break
        }
        eventName = ""
        dataBuffer = ""
    }

    for try await line in bytes.lines {
        if line.isEmpty {                       // blank line = end of one event
            flush()
        } else if line.hasPrefix("event:") {
            eventName = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
        } else if line.hasPrefix("data:") {
            dataBuffer += line.dropFirst(5).trimmingCharacters(in: .whitespaces)
        }
    }
    flush() // in case the stream ends without a trailing blank line
}
```

Usage — the caller collects tokens into a bubble and saves the conversation id:

```swift
var conversationId: Int? = existingThreadId   // nil for a new chat
var reply = ""

try await streamChatTurn(baseURL: base, token: token,
                         message: userText, conversationId: conversationId) { event in
    switch event {
    case .token(let t):
        reply += t
        // update the UI bubble on the main actor
    case .toolResult(let tool, let data):
        // decode `data` per `tool` and render a card
        break
    case .done(let done):
        conversationId = done.conversationId   // persist for the next turn

        switch done.conversationStatus {
        case "completed":            break // intake finished — hide the input box
        case "emergency_signposted": break // surface the signpost; close the thread
        default:                     break // nil — conversation continues
        }

        switch done.status {
        case "error":             break // show a manual retry affordance
        case "guardrail_blocked": break // accompanies emergency_signposted
        default:                  break // "ok"
        }
        // Re-enable the input here — one turn in flight per conversation (§4.3).
    }
}
```

The intake endpoint is identical — POST to `/intake/turn` and add
`appointment_id` on the first turn.

---

## 9. Client checklist

- [ ] Reuse the Laravel Sanctum token; send it as `Authorization: Bearer <token>`.
- [ ] Treat the token as an opaque string (survives the future switch to JWT).
- [ ] Send **only** `message` (+ `conversation_id` to continue). Never send history.
- [ ] Set `Accept: text/event-stream` and consume the response as a stream.
- [ ] Point builds at **`aiapp`** (singular) — `aiapps.broccolicare.ie` does not exist.
- [ ] Concatenate `token` events in order; render `tool_result` events as cards
      (§4.1), and **silently ignore unrecognised tool names**.
- [ ] Build a **`prepare_booking`** handler (§4.1.1) — prefill `BookingGlobalViewModel`,
      never route past `BookingConfirmationView`. **Do not handle `start_booking`.**
- [ ] Decode every `prepare_booking` field except `action`/`department_id`/`is_gp`/
      `display` as **optional**; a null `reason` is normal, not an error.
- [ ] **Chatbot:** hold `conversation_id` in memory only, never on disk (§4.2).
- [ ] **Intake:** persist `conversation_id` keyed by `appointment_id` and resume it;
      clear it on `conversation_status == "completed"` (§4.2).
- [ ] For intake, pass `appointment_id` on the first turn only; stop the input box
      when `conversation_status == "completed"`.
- [ ] Handle all three `done.status` values — `ok`, `error`, `guardrail_blocked` — and
      the full `error_code` list (§6.1). **Only `provider_error` is retryable.**
- [ ] On `emergency_signposted`: **close the composer client-side** (the server won't)
      and show a `tel:` 112 affordance. Blocked on clinical sign-off of the term list.
- [ ] Expect an output-phase guardrail block to **drop that turn's tool cards** (§6.2).
- [ ] Set the request timeout to **~120s**; expect a silent socket with no keepalive
      and show a spinner, not a typewriter.
- [ ] **Serialise turns:** one in flight per conversation — disable input until `done`.
- [ ] **Never auto-retry a dropped turn** (no idempotency — it would duplicate).
      Offer manual retry; backoff on `provider_error` starting **≥30s**.
- [ ] Don't display `scheduled_at` until the timezone question is settled (§4.1).
- [ ] Don't build a "manage reminders" UI — the API is create-only (§4.1).
- [ ] Check `Content-Type` / status to tell an SSE stream from a JSON error envelope.
- [ ] Handle both HTTP-level errors (4xx/5xx envelope) and turn-level errors
      (`done.status == "error"`), and back off on `429` if it appears.
- [ ] On `401`, re-authenticate with Laravel and retry.
- [ ] Generate and log an `X-Correlation-ID` per request for support traceability.
```
