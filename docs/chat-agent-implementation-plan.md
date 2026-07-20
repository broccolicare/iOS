# Implementation Plan — Health Assistant (Chat Agent)

Phase 1 of the AI backend integration: the **24×7 chatbot**, reached from a new tile on
the patient home screen.

**Contract:** [`ios-integration-guide.md`](ios-integration-guide.md) — read §4 (chat
turn), §4.1 (tool payloads), §4.2 (session persistence), §6.1 (`error_code`) before
starting.

> ## Guiding principle
>
> **This plan is driven by the API contract, not by the design.** The mockup is a
> **visual reference** for layout, colour, and typography — not a functional spec.
>
> We implement exactly what `/chatbot/turn` supports today. Where the design implies
> data the API does not return, we build the simpler thing that works now and list the
> richer version in [§3 Deferred](#3-deferred-to-later-phases) with a note on what would
> unblock it. **No feature here requires a backend change.**

---

## 1. Scope

A single new screen, `HealthAssistantView`, reached from a new grid tile on
`PatientHomeView`. All conversation happens on that screen. The chat is **ephemeral**:
leaving the screen discards the thread; re-entry starts a new conversation (guide §4.2).

Styled per the mockup: header "Health Assistant" / "Always available", assistant bubbles
(slate, left, green avatar badge), user bubbles (white, right, bordered), composer with
a green circular send button, persistent disclaimer footer.

---

## 2. What we build (everything below is fully supported today)

### 2.1 The conversation loop
Send a message, stream the reply, render it. Reuse `conversation_id` within the session.
This is the whole feature; everything else is trim.

### 2.2 Local starter chips ✅ decided
The mockup's three chips (`My appointments`, `Set reminder`, `Health tips`) are **local
static UI**, not server data — tapping one sends it as a normal message. **Confirmed:
they stay local.** This is permanent for this screen, not a deferral.

Two contract facts make this the only option: there is no "create conversation" call, so
**nothing can stream before the user's first message**; and `offer_quick_replies` is
**intake-exclusive** — the chatbot tool set has no quick-reply tool at all (guide §4.1).
Hide the chips after the first message. Do **not** build a server-driven chip renderer
here; that belongs to the intake phase.

### 2.3 Required states
Not decoration — each is forced by the contract:

| State | Why |
|-------|-----|
| **Thinking indicator** | Process-then-stream: **zero bytes for up to ~120s**, then a burst (guide §4). Not a typewriter — text arrives all at once. |
| **Composer disabled in-flight** | No server-side concurrency lock; the client **must** serialise one turn per conversation (guide §4.3). |
| **Manual retry** | `done.status == "error"`. Only `provider_error` is retryable, backoff **≥30s**. **Never auto-retry** — no idempotency, it would double-post (guide §6.1). |
| **Emergency signpost** | On `emergency_signposted` the server does **not** close the thread — the client must (guide §5). Composer disabled + `tel:112`. Gated on clinical sign-off, see §7. |

### 2.4 Tool cards — build the two that are self-contained

| Tool | What we build | Why it's safe to build now |
|------|---------------|----------------------------|
| `prepare_booking` | Card → prefill `BookingGlobalViewModel`, push the existing booking form | Payload is **complete and stable** — owned entirely by the AI service, no Laravel dependency, makes no network call |
| `create_medication_reminder` | Simple confirmation card (`id`, `status`) | Payload is fully rendered by what it returns |
| `lookup_appointments` | **Minimal** card — see §2.5 | Payload is thin; the rich version is deferred |
| unknown / `start_booking` | **Ignore silently** (`switch` + no-op `default`) | Guide §4.1. `start_booking` is deprecated — no handler |

For `prepare_booking`: decode every field except `action`/`department_id`/`is_gp`/
`display` as **optional**, implement `service_id`-else-`service_hint`, and treat a null
`reason` as normal. Fall back to `SpecialtyListView` when `service_hint` doesn't resolve.

> ⚠️ **Never route past `BookingConfirmationView`.** With `covered: true` Stripe is
> skipped, making that screen the only human checkpoint before a real appointment is
> created.

### 2.5 The appointment card — minimal by design

`lookup_appointments` returns only `{id, specialty, scheduled_at, status}`. So we render
**specialty + status**, and make the card tappable → the existing appointment detail
screen, reusing the id-to-detail flow that
[`navigateToBookingFromNotification`](../Broccoli/GlobalViewModels/BookingGlobalViewModel.swift#L1285-L1305)
already implements for push notifications.

Two deliberate omissions:

- **No time displayed — ✅ decided, and not a temporary workaround.** Time slots are
  owned by the booking flow and come from Laravel; the chat card is not where a patient
  reads an appointment time. This also avoids the `scheduled_at` timezone problem
  entirely: the payload carries **no timezone normalisation**, so if Laravel sends a
  naive timestamp there is nothing indicating its zone, and Ireland observes DST
  (guide §4.1). A wrong appointment time in a health app is a clinical-safety issue, not
  a formatting bug.
  **Consequence:** questions-doc Q1 no longer blocks this feature. It still matters for
  any future surface that *does* render an AI-supplied timestamp.
- **No doctor name, modality, or Join call button.** None of those fields exist in the
  payload. See §3.

The fetch happens **on tap, not on render** — so the transcript stays cheap and there is
no inline loading state to manage.

---

## 3. Deferred to later phases

Design elements we are consciously **not** building now, each with what would unblock it:

| Deferred | Why | Unblocked by |
|----------|-----|--------------|
| Doctor name on the appointment card | Not in the `lookup_appointments` payload | Backend adds it, **or** we accept a per-card Laravel fetch |
| Inline **"Join call"** button | Needs full `BookingData` + Agora token; not in the payload | Same as above — then embed the existing `VideoCallButton` |
| Appointment **time** | ✅ **Decided out, not deferred** — time slots come from the booking flow, not chat (§2.5) | n/a — no plans to add it here |
| **"Video call"** modality label | Field **does not exist** in the AI payload *or* in `BookingData`; every booking is implicitly video | A modality field added to Laravel |
| Server-driven quick replies | `offer_quick_replies` is intake-exclusive | The intake phase |
| Typewriter streaming | Backend is process-then-stream | Questions-doc **Q6** (SSE heartbeat / incremental streaming) |
| Chat history | No read endpoint; chat is ephemeral by decision | Product decision reversal |

**None of these block a working chat agent.** The richest one — a full appointment card
with Join call — is a well-understood follow-up: fetch `BookingData` by id and embed
[`VideoCallButton`](../Broccoli/DesignSystem/Components/VideoCallButton.swift), which
already handles token fetch, call-window gating and navigation.

---

## 4. Architecture

Follows existing conventions: `Endpoint` → `Service: BaseService` → ViewModel, with
`SecureStore` for the token and `Router` for navigation.

### 4.1 One deliberate deviation: feature-scoped ViewModel

Every other domain uses a `*GlobalViewModel` injected app-wide in
[`BroccoliApp.swift`](../Broccoli/App/BroccoliApp.swift#L20-L55). **Chat should not.**

A `@StateObject private var vm = ChatViewModel(...)` owned by `HealthAssistantView` makes
ephemerality **structural** rather than a rule someone must remember: pop the view and
the `conversation_id` dies with it. A global would survive navigation and quietly violate
guide §4.2. Worth a comment explaining why.

### 4.2 New files

```
Broccoli/
├── App/Environment/
│   └── AppEnvironment.swift              [MODIFY] add aiBaseURL
├── Networking/
│   ├── HTTP/
│   │   ├── SSEClient.swift               [NEW] SSE transport
│   │   └── ChatEndpoint.swift            [NEW] /chatbot/turn
│   └── Models/
│       └── ChatModels.swift              [NEW] wire types + tool payloads
├── Services/
│   └── ChatService.swift                 [NEW] ChatService: BaseService
├── Features/Patient/HealthAssistant/
│   ├── HealthAssistantView.swift         [NEW] screen
│   ├── ChatViewModel.swift               [NEW] feature-scoped VM
│   └── Components/
│       ├── ChatBubbleView.swift          [NEW]
│       ├── StarterChipsView.swift        [NEW] §2.2 — local, not server-driven
│       ├── ChatAppointmentCardView.swift [NEW] §2.5 — minimal, tap-to-detail
│       ├── ChatBookingCardView.swift     [NEW] prepare_booking
│       ├── ChatReminderCardView.swift    [NEW] create_medication_reminder
│       ├── TypingIndicatorView.swift     [NEW] the ~120s wait
│       ├── EmergencyBannerView.swift     [NEW] signpost + tel:112
│       └── ChatComposerView.swift        [NEW] input + send
├── Utilities/Routing/
│   └── Route.swift                       [MODIFY] case healthAssistant
└── Resources/Assets.xcassets/
    └── health-assistant.imageset         [NEW] tile background
```

Plus `[MODIFY]` to [`BroccoliApp.swift`](../Broccoli/App/BroccoliApp.swift#L70) (nav
destination) and [`PatientHomeView.swift`](../Broccoli/Features/Patient/PatientHomeView.swift#L131-L161)
(the tile).

### 4.3 The SSE client — the only genuinely new infrastructure

**There is no streaming anywhere in the codebase today.** `HTTPClient` is entirely
`session.data(for:)` → `Data` → decode. Four constraints:

1. **`URLSession.bytes(for:)`** with `for try await line in bytes.lines` — no third-party
   dependency. Reference parser in guide §8.
2. **Its own `URLSessionConfiguration` with `timeoutIntervalForRequest = 120`.** Do not
   reuse `URLSession.shared` — the 60s default will cut off legitimate turns, and the
   socket is silent throughout so there is no byte to reset an idle timer.
3. **Set `Accept: text/event-stream` via `setValue(_:forHTTPHeaderField:)`.**
   [`HTTPClient.swift:108`](../Broccoli/Networking/HTTP/HTTPClient.swift#L108) assigns
   `allHTTPHeaderFields` wholesale, which clobbers — don't replicate that ordering bug.
4. **Read the token once at connect** from `SecureStore.Keys.accessToken`; a long-lived
   stream can't pick up a rotation mid-flight.

Expose `AsyncThrowingStream<TurnEvent, Error>`; map failures into the existing
`HTTPError` → `ServiceError` chain so the ViewModel handles errors uniformly.

**Decide explicitly: should a chat 401 force a global logout?** Today any 401 posts
`.unauthorizedErrorReceived`, which
[force-logs-out and pops to login](../Broccoli/App/BroccoliApp.swift#L61-L69). There is
**no token refresh implemented anywhere** — `AuthService.refreshToken` exists with zero
callers and the refresh token is never persisted — so the guide's "re-authenticate and
retry" is not currently achievable. **Recommend posting the same notification** for
consistency, but make it a conscious choice.

### 4.4 `AppEnvironment` — a second base URL

The AI backend is a **different host** from Laravel:

| | Host |
|---|---|
| Laravel (`apiBaseURL`) | `https://admin.broccolicare.ie/api` |
| AI backend (`aiBaseURL`) | `https://aiapp.broccolicare.ie` |

Add `aiBaseURL` to
[`AppEnvironment`](../Broccoli/App/Environment/AppEnvironment.swift#L31-L63) for all three
cases. **The hostname is `aiapp` — singular.** `aiapps` does not resolve.

> ⚠️ Production currently points at the **staging** host (placeholder — questions doc
> Q4). Until infra confirms production isolation, **synthetic test data only.**

---

## 5. Phases

### Phase 1 — Plumbing (no UI) · M
1. `AppEnvironment.aiBaseURL` (§4.4)
2. `ChatModels.swift` — `TurnRequest`, `TurnEvent`, `TurnDone`, tool payloads
3. `ChatEndpoint.swift` — `POST /chatbot/turn`
4. `SSEClient.swift` — per §4.3
5. `ChatService.swift` — `BaseService` subclass, constructor-injected, wrapping calls in
   `handleServiceError` per the
   [`PackageService`](../Broccoli/Services/PackageService.swift) template
   (remember `super.init()`)

**Exit:** a temporary harness sends "hello" to staging and prints `token` events then
`done` with a `conversation_id`.

### Phase 2 — Screen shell & navigation · S · *parallel with Phase 1*
1. `Route.swift` → `case healthAssistant`
2. `BroccoliApp.swift` nav destination
3. `health-assistant` imageset (**a missing name fails silently as a blank tile**)
4. Tile in the **bottom grid** of `PatientHomeView` (~L131-161), copying the
   `medical-tourism` pattern:

```swift
Button(action: { router.push(.healthAssistant) }) {
    SmallActionTile(title: "Health Assistant", backgroundImage: "health-assistant")
        .frame(height: 130)
}.buttonStyle(.plain)
```

> Do **not** use the top grid — it dispatches on `service.title` string comparison
> (`PatientHomeView.swift:84-92`), a pattern not worth extending.

5. `HealthAssistantView` shell: header, greeting + starter chips, composer, disclaimer.
   No networking.

**Exit:** tile navigates; screen matches the mockup statically.

### Phase 3 — Conversation loop · M
1. `ChatViewModel` (§4.1) — `@Published messages`, `isTurnInFlight`, in-memory
   `conversationId`
2. Send → stream → append `token` text → finalise on `done`
3. Serialise: composer disabled while `isTurnInFlight`
4. Typing indicator from send until first event
5. All three `done.status` values and the full `error_code` table (guide §6.1):
   `ok` → finalise · `error` → streamed fallback + manual retry (≥30s backoff, retry
   **only** on `provider_error`) · `guardrail_blocked` → render deflection as a normal
   message
6. **Clear pending tool cards** when a turn ends `guardrail_blocked` — an output-phase
   block **drops that turn's cards** (guide §6.2)

**Exit:** multi-turn conversation works; `conversation_id` reused in-session, gone on exit.

### Phase 4 — Tool cards · M
`prepare_booking`, `create_medication_reminder`, and the minimal `lookup_appointments`
card (§2.4, §2.5). Unknown tools ignored.

**Exit:** all three render; unknown tools don't break the stream.

### Phase 5 — Safety & resilience · M
Emergency banner + composer lock + `tel:112`; connection-drop manual retry; defensive
`429` handling (`Retry-After`, else backoff); VoiceOver labels and Dynamic Type.

---

## 6. Testing

**Unit:** SSE parser (multi-line `data:`, blank-line boundaries, unknown events,
truncated stream); `error_code` → retry-policy mapping; `prepare_booking` decoding with
every optional absent; unknown-tool no-op.

**Integration (staging, synthetic data only):** happy path; multi-turn id reuse;
`prepare_booking` through to `BookingConfirmationView`; forced `provider_error`;
emergency signpost.

**Manual:** kill the network mid-turn (no auto-retry); background the app mid-turn;
rapid double-send (serialisation); a >60s turn (confirm the 120s timeout is in effect).

---

## 7. Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| ~120s silent wait feels broken | High — the core UX complaint | Honest typing indicator; consider "still working…" after ~15s. Heartbeat requested (questions doc Q6). |
| Emergency false positives | **High — patient-facing** | Detection is keyword-only and the term list is **not clinically signed off**. 🛑 **The emergency UI must not ship before sign-off** (questions doc Q2). |
| SSE parser edge cases | Medium — silent truncation | Test the parser directly; log unknown events in debug rather than swallowing. |
| First streaming code in the codebase | Medium — no local precedent | Keep `SSEClient` narrow and independently testable. |
| Production points at staging | **High — release blocker** | Questions doc Q4; synthetic data only until resolved. |

---

## 8. Out of scope

- **Intake module** (`/intake/turn`) — next phase. Note the **opposite** persistence
  rule: intake `conversation_id` is **persisted** per `appointment_id` (guide §4.2).
  Don't let chat's ephemeral pattern leak into it.
- Everything in [§3 Deferred](#3-deferred-to-later-phases).
- **`additionalNotes` fix** — separate, blocked on Laravel (questions doc D4).
