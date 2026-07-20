# iOS Integration — Round 3: Decisions & Remaining Questions

On the **Broccoli AI Backend** integration (`/chatbot/turn`, `/intake/turn`).

**Status:** Rounds 1 and 2 have been answered by the backend team and folded into
`ios-integration-guide.md`. Round 2's answers were thorough and closed most of what was
outstanding. This round records **our decisions** (things the backend was waiting on)
and lists what is still open.

---

## ✅ Corrections we've accepted

**The staging hostname was wrong in our config — fixed.** We verified it independently
on 2026-07-20:

```
aiapps.broccolicare.ie  → curl: (6) Could not resolve host   (does not exist)
aiapp.broccolicare.ie   → HTTP 200  {"status":"ok","version":"0.0.0"}
                          /ready → {"status":"ready","checks":{"database":"ok"}}
```

Both build configs now point at **`aiapp`** (singular). Thanks for catching it.

**`start_booking` → `prepare_booking`.** We are not writing a `start_booking` handler.
Agreed that the redirect was a downgrade over our existing native flow — the second
Safari login was the blocker, and removing the question entirely is the right call.

---

## 🟢 Our decisions — these unblock you

### D1. Intake IS exempt from our ephemeral-session rule ✅ Your recommendation accepted
Your clinical reasoning persuaded us, particularly that an abandoned intake yields *no*
summary — so the failure mode is a lost clinical record, not a lost transcript.

**What we will do:**
- Persist **only** the intake `conversation_id`, scoped to its `appointment_id`, and
  resume it on re-entry.
- Chatbot remains **fully ephemeral** — never written to disk.
- Clear the stored intake id on `conversation_status == "completed"`.

**→ For your §7 gap: please implement `resume`, not `409`.** Since we now resume with
the stored `conversation_id`, a duplicate-start guard should prefer returning the
existing in-progress intake over rejecting. We'd still like the guard — our resume path
can't help if the user reinstalls mid-intake and loses the stored id.

### D2. We will enforce the emergency close client-side ✅
Given the server does not gate later turns on `emergency_signposted`:
- We disable the composer for that thread on our side.
- We show a native `tel:` affordance for **112** (your recommendation; EU-wide and
  works alongside 999 in Ireland).

**No server-side gate needed for now** — but see Q3 below, this is conditional.

### D3. `prepare_booking` — building against it now
Decoding all fields except `action`/`department_id`/`is_gp`/`display` as optional,
implementing the `service_id`-else-`service_hint` rule, and treating a null `reason` as
normal. We will not route past `BookingConfirmationView`.

Sign-off on `booking-in-chat.md` §4.2 and §5 to follow separately once we've read it.

### D4. `additionalNotes` bug — confirmed on our side, logged
You were right. In our codebase `additionalNotes` is declared in
`BookingGlobalViewModel` and written by **both** booking forms, but neither
`initializePayment` nor `confirmPayment` includes it in the request payload — so
patient-entered notes are silently discarded today.

**We're logging it, not fixing it yet**, since there is nothing on the Laravel side to
receive it. When `POST /payments/bookings/confirm` accepts a notes field, we'll wire
both paths in the same change. Please flag when that lands.

---

## 🔴 Still open — blocking or safety-relevant

### Q1. `scheduled_at` timezone — we support your proposal, please raise it
**Yes, please normalise outbound datetimes to UTC with an explicit offset.** We'll
render in the device's local zone.

Until that lands we are **not displaying `scheduled_at` at all**. For a health app, a
wrong appointment time is a clinical-safety issue, not a formatting bug, and Ireland's
DST makes a naive timestamp genuinely ambiguous. Please confirm when it ships so we can
turn the UI on.

### Q2. Red-flag term list — clinical sign-off needed before release
Noted that detection is keyword-only and the list is marked **not clinically signed
off**. This now has more weight on our side than it did: because of D2, a false
positive **hard-closes the user's thread and shows an emergency number**.

We are treating clinical sign-off as a **release blocker** for the emergency UI. Who
owns it, and what's the timeline?

### Q3. Do you still want a server-side emergency gate?
We can enforce the close client-side today (D2), so nothing is blocked. But a
client-only gate is bypassed by any other client, and by our own app if a future
release regresses it. **Our view: worth adding server-side eventually**, low urgency.
Your call — we're not waiting on it.

### Q4. Production hostname + staging data isolation — unchanged, still blocking release
Both still outstanding from Round 2 §11:
1. **What is the production hostname?** Our production build config currently points at
   the staging host as a placeholder. Shipping that way would put patient data in a
   non-production environment — a release blocker, not a config detail.
2. **Is staging backed by a separate Laravel instance and database?** Until this is
   answered *in writing*, we are using **synthetic records only** and assuming staging
   may touch production data.

---

## 🟡 Lower priority / noted

### Q5. Retention — we'll write the DPIA against reality
Understood: TTL defaults to `0`, and the purge job is never invoked, so **transcripts
are currently retained indefinitely with no automated deletion**. We'll write the DPIA
against that, not against an intended policy.

Also noted, and we agree it's serious: enabling a TTL would **cascade-delete intake
summaries**, which plausibly have a longer lawful retention basis than chat
transcripts. Flagging that we consider this a Legal + Clinical blocker before any TTL
is set, and it likely needs a schema change so summaries survive transcript purge.

### Q6. SSE heartbeat — accepted as a scoped change, no pressure
Understood that it requires restructuring process-then-stream, not a few lines. We've
designed the client so heartbeats are **optional** — liveness does not depend on them,
so they can land later without a client release. Whenever you get to it.

### Q7. Idempotency — agreed it matters more than "lower priority" implies
Your point stands: because `provider_error` is retryable *and* is what an open circuit
looks like, retry is a path we will genuinely take. We're using manual-retry-only with
backoff ≥30s in the meantime, so duplicates stay user-initiated.

### Q8. API versioning
Still no scheme. We don't need a formal contract version to key off today — the
unknown-tool rule and optional-field decoding give us enough forward compatibility.
Flagging that our answer may change once there are two live client versions in the
field.

---

## Summary — who owns what

| # | Item | Owner | Status |
|---|------|-------|--------|
| — | Staging hostname `aiapp` (singular) | iOS | ✅ Fixed & verified |
| D1 | Intake exempt from ephemeral rule | iOS | ✅ Decided — **backend: implement resume, not 409** |
| D2 | Emergency close + 112 affordance | iOS | ✅ Decided — gated on Q2 |
| D3 | `prepare_booking` handler | iOS | 🔨 Building |
| D4 | `additionalNotes` never sent | iOS + Laravel | ⏸ Logged, blocked on Laravel notes field |
| Q1 | `scheduled_at` UTC normalisation | Backend | 🔴 We support it — please raise. UI off until then |
| Q2 | Red-flag list clinical sign-off | Clinical | 🔴 **Release blocker** for emergency UI |
| Q3 | Server-side emergency gate | Backend | 🟡 Optional, your call |
| Q4 | Production hostname | Infra | 🔴 **Release blocker** |
| Q4 | Staging vs production data isolation | Infra | 🔴 Synthetic data only until answered |
| Q5 | Retention / TTL cascade to summaries | Legal + Clinical | 🟡 Before any TTL is set |
| Q6 | SSE heartbeat | Backend | 🟡 Accepted, no pressure |
| Q7 | Idempotency | Backend | 🟡 Logged |
| Q8 | API versioning | Backend | 🟢 Not needed yet |
