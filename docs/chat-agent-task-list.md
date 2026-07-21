# Task List — Health Assistant (Chat Agent)

Granular breakdown of
[`chat-agent-implementation-plan.md`](chat-agent-implementation-plan.md). Contract
reference: [`ios-integration-guide.md`](ios-integration-guide.md).

**How to use:** each phase opens with a **progress checklist** — tick those boxes as you
go. The detailed spec for every task follows below it. Task IDs (`P1-01`) are stable;
reference them in commits and PRs.

**Sizes:** `XS` <30min · `S` ~1h · `M` ~half day · `L` ~1 day+

---

## Overall progress

| Phase | Done | Status |
|-------|------|--------|
| 1 · Plumbing | 10 / 11 | 🟨 In progress — P1-10 needs a staging run |
| 2 · Shell & nav | 8 / 10 | 🟨 In progress — P2-03 artwork, P2-10 mockup check |
| 3 · Conversation loop | 9 / 10 | 🟨 In progress — P3-09 needs a device check |
| 4 · Tool cards | 6 / 7 | 🟨 In progress — P4-04 needs an end-to-end run |
| 5 · Safety | 0 / 6 | ⬜ Not started |
| **Total** | **33 / 44** | |

---

## Phase 1 — Plumbing (no UI)

**Goal:** one turn streams end-to-end against staging, proven without any UI.
**Parallel with Phase 2.**

### ✅ Phase 1 checklist

- [x] **P1-01** · Add `aiBaseURL` to `AppEnvironment` · XS
- [x] **P1-02** · Core wire models · S
- [x] **P1-03** · Tool payload models · S
- [x] **P1-04** · `ChatErrorCode` + retry policy · XS
- [x] **P1-05** · `ChatEndpoint` · XS
- [x] **P1-06** · SSE line parser (standalone) · M ⚠️ *critical path*
- [x] **P1-07** · `SSEClient` transport · M ⚠️ *critical path*
- [x] **P1-08** · 401 policy decision + implementation · S 🔸 *needs a decision first*
- [x] **P1-09** · `ChatService` · S ⚠️ *critical path*
- [~] **P1-10** · End-to-end harness · S — *written; awaiting a staging run with a signed-in user*
- [x] **P1-11** · Unit tests · M

---

#### P1-01 · Add `aiBaseURL` to `AppEnvironment` · XS
**File:** [`Broccoli/App/Environment/AppEnvironment.swift`](../Broccoli/App/Environment/AppEnvironment.swift#L31-L63)

Add an `aiBaseURL: String` property and populate all three presets. Distinct from
`apiBaseURL` — different host.

- development / staging / production → `https://aiapp.broccolicare.ie`

**Acceptance:** `AppEnvironment.current.aiBaseURL` resolves in all three build configs.
**⚠️ The hostname is `aiapp` — singular.** `aiapps` does not resolve in DNS. Production
is intentionally the staging host for now (questions doc Q4).

#### P1-02 · Core wire models · S
**File:** `Broccoli/Networking/Models/ChatModels.swift` *(new)*

- `TurnRequest` — `message: String`, `conversationId: Int?` (omit key when nil)
- `TurnDone` — `status`, `conversationId`, `conversationStatus`, `errorCode`
  (snake_case `CodingKeys`)
- `TurnEvent` enum — `.token(String)` · `.toolResult(tool: String, data: Data)` · `.done(TurnDone)`
- `ConversationStatus` — `nil` · `completed` · `emergencySignposted`
- `TurnStatus` — `ok` · `error` · `guardrailBlocked`

**Acceptance:** `TurnDone` decodes the guide §4 sample payload. Unknown `status` /
`conversation_status` strings decode to a safe unknown case rather than throwing.

#### P1-03 · Tool payload models · S
**File:** `Broccoli/Networking/Models/ChatModels.swift`

- `PrepareBookingPayload` — **only** `action`, `departmentId`, `isGp`, `display` are
  non-optional. `serviceHint`, `serviceId`, `dateFrom`, `dateTo`, `timePreference`,
  `reason` are **all optional** (guide §4.1.1)
- `BookingDisplay` — `title`, `cta` non-optional; `subtitle` optional
- `MedicationReminderPayload` — `id: Int`, `status: String`
- `LookupAppointmentsPayload` — `appointments: [ChatAppointment]` (`id`, `specialty`,
  `scheduledAt`, `status`)

**Acceptance:** `PrepareBookingPayload` decodes successfully with **every** optional
field absent, and again with all present. Extra unknown JSON keys do not throw.

#### P1-04 · `ChatErrorCode` + retry policy · XS
**File:** `Broccoli/Networking/Models/ChatModels.swift`

Enum of the five codes (guide §6.1) + unknown, with `var isRetryable: Bool` — **`true`
only for `providerError`**.

**Acceptance:** unit test asserts exactly one code is retryable.

#### P1-05 · `ChatEndpoint` · XS
**File:** `Broccoli/Networking/HTTP/ChatEndpoint.swift` *(new)*

Conform to the existing [`Endpoint`](../Broccoli/Networking/HTTP/Endpoint.swift)
protocol. `case chatbotTurn(TurnRequest)` → `POST /chatbot/turn`.

**Acceptance:** produces the correct path, method and body; omits `conversation_id`
entirely when nil (does not send `null`).

#### P1-06 · SSE line parser (standalone) · M
**File:** `Broccoli/Networking/HTTP/SSEParser.swift` *(new)*

**Keep this separate from the transport** — it's the piece most likely to have edge-case
bugs and it must be unit-testable without a network.

Accumulate `event:` / `data:` lines, flush on blank line, flush again at stream end.
Per the SSE spec, join multiple `data:` lines with `\n`.

**Acceptance:** given a line sequence, emits the right ordered events. Handles: unknown
event names (ignored), multi-line `data:`, missing trailing blank line, `:` comment
lines (ignored), and a truncated stream.

#### P1-07 · `SSEClient` transport · M
**File:** `Broccoli/Networking/HTTP/SSEClient.swift` *(new)*

`URLSession.bytes(for:)` + `for try await line in bytes.lines`, feeding `SSEParser`.
Returns `AsyncThrowingStream<TurnEvent, Error>`.

Four hard requirements (plan §4.3):
1. **Own `URLSessionConfiguration`** with `timeoutIntervalForRequest = 120` — do **not**
   use `URLSession.shared` (its 60s default cuts off valid turns)
2. `Accept: text/event-stream` set via `setValue(_:forHTTPHeaderField:)` — **not** via
   `allHTTPHeaderFields`, which clobbers
3. Read the token **once at connect** from `SecureStore.Keys.accessToken`
4. Non-200 → read the JSON error envelope and throw, do **not** parse as SSE

**Acceptance:** a 200 SSE response yields ordered events; a 401 throws before any event;
a mid-stream disconnect surfaces an error rather than completing silently.

#### P1-08 · 401 policy decision + implementation · S
**File:** `Broccoli/Networking/HTTP/SSEClient.swift`

🔸 **Decision required before coding** (plan §4.3). Recommended: post
`.unauthorizedErrorReceived`, consistent with
[`HTTPClient`](../Broccoli/Networking/HTTP/HTTPClient.swift#L171). Note there is **no
token refresh implemented anywhere** — `AuthService.refreshToken` has zero callers — so
the guide's "re-authenticate and retry" is not achievable today.

**Acceptance:** behaviour is deliberate, implemented, and commented with the reason.

#### P1-09 · `ChatService` · S
**File:** `Broccoli/Services/ChatService.swift` *(new)*

Protocol + `final class ChatService: BaseService`, constructor-injected `SSEClient`.
Follow the [`PackageService`](../Broccoli/Services/PackageService.swift) template —
**remember `super.init()`**. Map failures through `handleServiceError` into
`ServiceError`.

**Acceptance:** exposes `func streamTurn(message:conversationId:) -> AsyncThrowingStream<TurnEvent, Error>`;
transport errors surface as `ServiceError`.

#### P1-10 · End-to-end harness · S
**File:** temporary — a test target case or a scratch SwiftUI preview. **Delete before
merge.**

Send `"hello"` to staging, print every event.

**Acceptance:** prints ≥1 `token` event then exactly one `done` carrying a
`conversation_id`. Sending that id back continues the same thread.
**Use synthetic data only** (questions doc Q4).

#### P1-11 · Unit tests · M
**File:** `BroccoliTests/ChatSSETests.swift` *(new)*

Cover P1-06 parser cases, P1-03 optional-field decoding, P1-04 retry policy.

**Acceptance:** all pass; parser tests run with no network.

---

## Phase 2 — Screen shell & navigation

**Goal:** the tile navigates to a screen that matches the mockup statically.
**No networking.** Parallel with Phase 1.

### ✅ Phase 2 checklist

- [x] **P2-01** · Add route case · XS
- [x] **P2-02** · Wire nav destination · XS
- [~] **P2-03** · Tile artwork · XS — *placeholder gradient in place; needs real artwork*
- [x] **P2-04** · Home screen tile · XS
- [x] **P2-05** · `HealthAssistantView` scaffold + header · S
- [x] **P2-06** · `ChatBubbleView` · S
- [x] **P2-07** · `StarterChipsView` · S
- [x] **P2-08** · `ChatComposerView` · S
- [x] **P2-09** · Disclaimer footer · XS
- [~] **P2-10** · Static assembly + preview · S — *assembled; awaiting side-by-side vs mockup*

---

#### P2-01 · Add route case · XS
**File:** [`Broccoli/Utilities/Routing/Route.swift`](../Broccoli/Utilities/Routing/Route.swift)
→ `case healthAssistant`
**Acceptance:** compiles; `Route` remains `Hashable`.

#### P2-02 · Wire nav destination · XS
**File:** [`Broccoli/App/BroccoliApp.swift`](../Broccoli/App/BroccoliApp.swift#L70)
→ `case .healthAssistant: HealthAssistantView()` in the `navigationDestination` switch.
**Acceptance:** `Router.shared.push(.healthAssistant)` presents the screen.

#### P2-03 · Tile artwork · XS
**File:** `Broccoli/Resources/Assets.xcassets/health-assistant.imageset` *(new)*

**Acceptance:** the imageset exists at 1x/2x/3x. ⚠️ A missing/misspelled name **fails
silently as a blank tile** — verify visually, not just by compiling.

#### P2-04 · Home screen tile · XS
**File:** [`Broccoli/Features/Patient/PatientHomeView.swift`](../Broccoli/Features/Patient/PatientHomeView.swift#L131-L161)

Add to the **bottom grid**, copying the `medical-tourism` pattern:

```swift
Button(action: { router.push(.healthAssistant) }) {
    SmallActionTile(title: "Health Assistant", backgroundImage: "health-assistant")
        .frame(height: 130)
}.buttonStyle(.plain)
```

> **Do not use the top grid** — it dispatches on `service.title` string comparison
> (`PatientHomeView.swift:84-92`), a pattern not worth extending.

**Acceptance:** tile renders with artwork and navigates.

#### P2-05 · `HealthAssistantView` scaffold + header · S
**File:** `Broccoli/Features/Patient/HealthAssistant/HealthAssistantView.swift` *(new)*

Back button, "Health Assistant" title, green "Always available" subtitle, scrollable
transcript area, composer pinned at the bottom.
**Acceptance:** matches the mockup; back button pops.

#### P2-06 · `ChatBubbleView` · S
**File:** `.../Components/ChatBubbleView.swift` *(new)*

Assistant (slate, left, green avatar badge) and user (white, right, bordered) variants.
**Acceptance:** both render correctly with short and long multi-line text; supports
Dynamic Type.

#### P2-07 · `StarterChipsView` · S
**File:** `.../Components/StarterChipsView.swift` *(new)*

Three **local static** chips — `My appointments`, `Set reminder`, `Health tips` — wrapping
to a second row. Tap → callback with the chip's label.

> Local by decision (plan §2.2). **Not** server-driven — `offer_quick_replies` is
> intake-exclusive and nothing can stream before the first user message.

**Acceptance:** renders per mockup; tap invokes the callback; hides after the first user
message.

#### P2-08 · `ChatComposerView` · S
**File:** `.../Components/ChatComposerView.swift` *(new)*

Text field ("Message the assistant") + green circular send button. Must expose an
**enabled/disabled** state (used in P3-04) and grow to a few lines before scrolling.
**Acceptance:** send disabled when empty or when externally disabled; keyboard avoidance
works.

#### P2-09 · Disclaimer footer · XS
**File:** `HealthAssistantView.swift`

Persistent, below the composer: *"I can't diagnose or prescribe - for medical concerns,
book a consultation"*.
**Acceptance:** always visible, does not scroll with the transcript.

#### P2-10 · Static assembly + preview · S
Compose P2-05…P2-09 with hardcoded sample messages.
**Acceptance:** side-by-side with the mockup, layout/colour/spacing match. No networking.

---

## Phase 3 — Conversation loop

**Goal:** a real multi-turn conversation. **Depends on Phases 1 + 2.**

### ✅ Phase 3 checklist

- [x] **P3-01** · `ChatViewModel` skeleton · S
- [x] **P3-02** · `ChatMessage` model · XS
- [x] **P3-03** · Send action + token accumulation · M ⚠️ *critical path*
- [x] **P3-04** · Turn serialisation · S
- [x] **P3-05** · `TypingIndicatorView` · S
- [x] **P3-06** · `done` handling — all three statuses · M ⚠️ *critical path*
- [x] **P3-07** · Retry policy · S
- [x] **P3-08** · Clear cards on output-phase block · S
- [~] **P3-09** · Scroll behaviour · S — *implemented; pinning needs a device check*
- [x] **P3-10** · Session teardown · XS

> Covered by `BroccoliTests/ChatViewModelTests.swift` (18 tests) against a stubbed
> service. **Not yet exercised against staging** — that lands with P5-06, alongside
> the still-pending P1-10 run.

---

#### P3-01 · `ChatViewModel` skeleton · S
**File:** `.../HealthAssistant/ChatViewModel.swift` *(new)*

`@MainActor final class ChatViewModel: ObservableObject` with
`@Published messages: [ChatMessage]`, `@Published isTurnInFlight: Bool`, and a
**private in-memory** `conversationId: Int?`.

⚠️ **Feature-scoped, not a `GlobalViewModel`** (plan §4.1) — owned as `@StateObject` by
the view so ephemerality is structural. **Add a comment explaining why**, or someone will
"fix" it later.

**Acceptance:** `conversationId` is never written to disk; popping the view deallocates
the VM.

#### P3-02 · `ChatMessage` model · XS
Discriminated: `.user(String)` · `.assistant(String)` · `.toolCard(ChatToolCard)` ·
`.systemNotice(...)`. Each with a stable `id` for `List`/`ForEach` diffing.
**Acceptance:** appending during streaming doesn't cause SwiftUI identity churn.

#### P3-03 · Send action + token accumulation · M
Wire send → `ChatService.streamTurn` → append `.token` text into the in-progress
assistant bubble.
**Acceptance:** the reply appears; concatenation preserves order and whitespace exactly.

#### P3-04 · Turn serialisation · S
Set `isTurnInFlight` on send, clear on `done` **or** error. Composer disabled throughout.

> Required — there is **no server-side concurrency lock**. Two turns on one
> `conversation_id` interleave and corrupt the transcript (guide §4.3).

**Acceptance:** rapid double-tap sends exactly one turn.

#### P3-05 · `TypingIndicatorView` · S
**File:** `.../Components/TypingIndicatorView.swift` *(new)*

Shown from send until the first event. **Not a typewriter** — the socket is silent for
up to ~120s, then everything arrives at once.
Consider escalating to "still working…" after ~15s.
**Acceptance:** appears immediately on send, disappears on the first event, and survives
a full 120s wait without looking stalled.

#### P3-06 · `done` handling — all three statuses · M
- `ok` → finalise the bubble
- `error` → render the streamed fallback text, then a **manual** retry affordance
- `guardrailBlocked` → render the streamed deflection as a normal assistant message

Always read and store `conversationId` from `done`.

**Acceptance:** each status renders correctly; `conversation_id` is captured on the very
first turn and reused thereafter.

#### P3-07 · Retry policy · S
Retry **only** on `providerError`; backoff **≥30s** (an open circuit breaker is
indistinguishable and resets after ~30s). **Never automatic** — no idempotency, so a
retry can double-post.
**Acceptance:** terminal codes show no retry button; retry is always user-initiated.

#### P3-08 · Clear cards on output-phase block · S
When a turn ends `guardrailBlocked`, **remove any `tool_result` cards emitted during that
turn** — an output block drops them server-side (guide §6.2).
**Acceptance:** a card rendered mid-turn disappears when the turn ends blocked.

#### P3-09 · Scroll behaviour · S
Auto-scroll to the newest message; don't yank the view if the user has scrolled up.
**Acceptance:** stays pinned during a burst; respects manual scrolling.

#### P3-10 · Session teardown · XS
On disappear, cancel any in-flight stream and drop `conversationId`.
**Acceptance:** re-entering the screen starts a genuinely new conversation.

---

## Phase 4 — Tool cards

**Goal:** the three supported cards render. **Depends on Phase 3.**

### ✅ Phase 4 checklist

- [x] **P4-01** · `tool_result` routing · S
- [x] **P4-02** · `ChatReminderCardView` · S
- [x] **P4-03** · `ChatBookingCardView` · M
- [~] **P4-04** · Booking prefill + navigation · M — *implemented; needs an end-to-end run*
- [x] **P4-05** · `ChatAppointmentCardView` (minimal) · M
- [x] **P4-06** · Appointment card tap-through · S
- [x] **P4-07** · Card tests · S

> **Prefill hazard, resolved.** Both booking forms call `resetBookingForm()` in
> `onAppear`, which destroys anything set before the push. The handoff therefore
> goes through `BookingGlobalViewModel.pendingChatPrefill`, which that reset
> deliberately does **not** clear, consumed via `consumeChatPrefill()` after the
> form has reset itself. Touching either `onAppear` means re-checking this ordering.
>
> ⚠️ `additionalNotes` (where `reason` lands) is **never sent to the backend** —
> `initializePayment` / `confirmPayment` don't include it. The prefill is display-only
> until that changes.
>
> P4-04 stays `[~]` until the card → form → `BookingConfirmationView` path is walked
> on device (P5-06).

---

#### P4-01 · `tool_result` routing · S
`switch` on the tool name with a **no-op `default`**.

> **Silently ignore unknown tools** — the server may add tools without a client release.
> **Do not write a `start_booking` handler**; it is deprecated and will be removed
> (guide §4.1).

**Acceptance:** an unknown tool name is ignored and does not interrupt the stream.

#### P4-02 · `ChatReminderCardView` · S
**File:** `.../Components/ChatReminderCardView.swift` *(new)*

Confirmation card from `MedicationReminderPayload`.

> ⚠️ **Word it so it does not imply in-app management** — the API is create-only, with no
> list, cancel, update or delete (guide §4.1).

**Acceptance:** renders; copy makes no promise of managing reminders in-app.

#### P4-03 · `ChatBookingCardView` · M
**File:** `.../Components/ChatBookingCardView.swift` *(new)*

Render from `display` (`title`, `subtitle`, `cta`). Ignore the card entirely if `action`
is not `"open_booking"`.
**Acceptance:** renders with every optional field absent; a null `reason` is treated as
normal, not an error.

#### P4-04 · Booking prefill + navigation · M
Map the payload onto `BookingGlobalViewModel` and push the existing booking form.
Implement **`service_id` if non-null, else resolve `service_hint`**. If it doesn't
resolve, push `SpecialtyListView` — chat saves taps, it must never dead-end.

> 🛑 **Never route past `BookingConfirmationView`.** With `covered: true` Stripe is
> skipped, making it the only human checkpoint before a real appointment is created.

**Acceptance:** tapping the card lands on the correct prefilled form; unresolvable hints
land on `SpecialtyListView`; the confirmation screen is always reached.

#### P4-05 · `ChatAppointmentCardView` (minimal) · M
**File:** `.../Components/ChatAppointmentCardView.swift` *(new)*

Render **specialty + status only** from the payload. Empty list → a short "no upcoming
appointments" message instead of an empty card.

> **No time, no doctor name, no Join call** — decided (plan §2.5, §3). Time is owned by
> the booking flow. **Never render the AI payload's `scheduled_at`.**

**Acceptance:** renders from payload alone with no extra network call.

#### P4-06 · Appointment card tap-through · S
Tap → fetch by id and push the existing appointment detail, mirroring
[`navigateToBookingFromNotification`](../Broccoli/GlobalViewModels/BookingGlobalViewModel.swift#L1285-L1305).
Fetch happens **on tap, not on render**.
**Acceptance:** tap opens the correct appointment; a failed fetch shows an error without
breaking the transcript.

#### P4-07 · Card tests · S
**Acceptance:** each card renders from a fixture; unknown tools no-op; `prepare_booking`
with all-optionals-absent renders.

---

## Phase 5 — Safety & resilience

**Goal:** safe failure modes. **Depends on Phase 3.**

### ✅ Phase 5 checklist

- [ ] **P5-01** · `EmergencyBannerView` · M 🛑 *gated on clinical sign-off*
- [ ] **P5-02** · Composer lock on signpost · S 🛑 *gated on clinical sign-off*
- [ ] **P5-03** · Connection-drop handling · S
- [ ] **P5-04** · Defensive `429` handling · S
- [ ] **P5-05** · Accessibility · M
- [ ] **P5-06** · Manual QA pass · M

---

#### P5-01 · `EmergencyBannerView` · M
**File:** `.../Components/EmergencyBannerView.swift` *(new)*

On `conversationStatus == .emergencySignposted`: prominent banner + the streamed
signpost text + a `tel:112` button.

> 🛑 **RELEASE GATE — must not ship before clinical sign-off** of the red-flag term list
> (questions doc Q2). Detection is **keyword-only** and the list is marked in backend
> code as *not clinically signed off*, so a false positive hard-closes a patient's thread
> and shows an emergency number.

**Acceptance:** banner renders; `tel:112` opens the dialler on device.

#### P5-02 · Composer lock on signpost · S
Permanently disable the composer for that thread — **the server does not gate later
turns**, only ownership is checked (guide §5).
**Acceptance:** no further message can be sent; the state survives backgrounding.

#### P5-03 · Connection-drop handling · S
On mid-stream failure: keep what was received, show a **manual** retry. **Never
automatic.**
**Acceptance:** killing the network mid-turn produces no automatic re-POST.

#### P5-04 · Defensive `429` handling · S
Honour `Retry-After` if present, else exponential backoff. Not emitted today but infra
may enable it.
**Acceptance:** a simulated 429 backs off instead of hammering.

#### P5-05 · Accessibility · M
VoiceOver labels on bubbles, cards and the send button; Dynamic Type through the
transcript; announce new assistant messages.
**Acceptance:** the full flow is navigable with VoiceOver; layout holds at the largest
accessibility text size.

#### P5-06 · Manual QA pass · M
Kill network mid-turn · background mid-turn · rapid double-send · a >60s turn (confirm
the 120s timeout is in effect) · emergency signpost · `prepare_booking` end-to-end.
**Acceptance:** all pass on device against staging with synthetic data.

---

## Definition of done (every task)

- [ ] Matches the contract in [`ios-integration-guide.md`](ios-integration-guide.md) —
      cite the section in the PR when behaviour is contract-driven
- [ ] No `conversation_id` written to disk (chat is ephemeral)
- [ ] New decoders tolerate unknown/extra JSON keys
- [ ] Unknown enum values degrade gracefully rather than throwing
- [ ] No auto-retry anywhere
- [ ] Tested against **staging with synthetic data only** (questions doc Q4)

---

## Summary

| Phase | Tasks | Size | Depends on |
|-------|-------|------|-----------|
| 1 · Plumbing | P1-01 … P1-11 | M–L | — |
| 2 · Shell & nav | P2-01 … P2-10 | M | — *(parallel with 1)* |
| 3 · Conversation loop | P3-01 … P3-10 | M–L | 1, 2 |
| 4 · Tool cards | P4-01 … P4-07 | M | 3 |
| 5 · Safety | P5-01 … P5-06 | M | 3 · **P5-01/02 gated on Q2** |

**Critical path:** P1-06 → P1-07 → P1-09 → P3-03 → P3-06. The SSE parser and transport
are the highest-risk items — no streaming code exists in the app today.

**Blocked:** only P5-01 and P5-02 (clinical sign-off). Everything else can proceed now.

**Legend:** ⚠️ critical path · 🔸 needs a decision first · 🛑 blocked
