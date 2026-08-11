# Laravel Internal (S2S) API — Integration Reference

**Status:** FastAPI side **built** ([`app/laravel/`](../app/laravel/)); Laravel side
**not yet exposed**. This doc is the contract Laravel must implement so the AI
backend can call Laravel directly instead of the current iOS-side workaround.
**Audience:** Laravel team (primary), backend + iOS (context).
**Worked example throughout:** the _"what are my appointments?"_ chatbot query.

---

## 1. Why this exists

Today, when a patient asks about their appointments in the Health Assistant, the
AI backend does **not** fetch domain data from Laravel. Instead the iOS app calls
Laravel's public API itself, using the logged-in user's Sanctum token (see
`ChatBookingCoordinator.openAppointment(id:)` on iOS, which fetches on tap via the
user's session). That is a workaround.

The target: the AI backend talks to Laravel **server-to-server (S2S)** over a
signed internal API, fetches the data, and streams it back to iOS as a
`tool_result`. iOS then only renders — it never calls Laravel for chat data.

```
Today (workaround)                     Target
──────────────────                     ──────
iOS → /chatbot/turn → AI backend       iOS → /chatbot/turn → AI backend
AI returns a card                      AI backend → Laravel /internal (HMAC-signed)
iOS → Laravel (user's token) ← extra   AI backend streams tool_result
iOS renders                            iOS renders
```

---

## 2. The FastAPI side is already built

For the appointment case, **no Python changes are required**. The pieces exist and
are waiting for Laravel to answer:

| Piece                                            | Location                                                      |
| ------------------------------------------------ | ------------------------------------------------------------- |
| Tool the model calls (`lookup_appointments`)     | [`app/tools/laravel_tools.py`](../app/tools/laravel_tools.py) |
| Client method (`list_patient_appointments`)      | [`app/laravel/client.py`](../app/laravel/client.py)           |
| Request signer (HMAC)                            | [`app/laravel/signing.py`](../app/laravel/signing.py)         |
| Expected response schema (`PatientAppointments`) | [`app/laravel/schemas.py`](../app/laravel/schemas.py)         |
| iOS renderer (`LookupAppointmentsPayload`)       | iOS `ChatModels.swift` / `ChatToolCardView.swift`             |

**The entire gap is that Laravel does not expose `/internal/...` yet and cannot
verify the AI backend's signature.** That is the work described below.

---

## 3. Request signing (shared by all internal endpoints)

The AI backend authenticates to Laravel with an **HMAC-SHA256 signature** over a
canonical view of each request — there is no user token on these calls. The
canonical string is (see [`signing.py`](../app/laravel/signing.py)):

```
method \n path \n sha256(body_hex) \n timestamp \n nonce
```

Sent in these headers:

| Header                | Value                                          |
| --------------------- | ---------------------------------------------- |
| `X-Signature`         | HMAC-SHA256 hex digest of the canonical string |
| `X-Timestamp`         | POSIX seconds (integer)                        |
| `X-Nonce`             | 32-hex-char random, unique per request         |
| `X-Signature-Version` | `v1`                                           |

**Three details that will cause every signature to be rejected if they drift:**

1. **`path` is the exact raw path Laravel receives** — includes the `/internal`
   prefix and any query string. FastAPI signs `request.url.raw_path`.
2. **`sha256(body)` is a lowercase hex digest.** For a bodyless `GET` it is
   `sha256("")` (the hash of empty bytes), _not_ an empty string.
3. **`method` is upper-case** (`GET`, `POST`).

### Middleware Laravel must add

```php
// app/Http/Middleware/VerifyAiSignature.php
public function handle(Request $request, Closure $next)
{
   $secret    = config('services.ai_backend.s2s_secret');
   $method    = strtoupper($request->method());
   $path      = $request->getRequestUri();          // MUST include /internal + query
   $bodyHash  = hash('sha256', $request->getContent());   // sha256("") for GET
   $timestamp = (string) $request->header('X-Timestamp');
   $nonce     = (string) $request->header('X-Nonce');


   // (a) clock window — reject stale requests (~300s skew tolerance)
   if (abs(time() - (int) $timestamp) > 300) abort(401, 'stale timestamp');


   // (b) replay protection — nonce must be unseen within the window
   if (Cache::has("ai_nonce:$nonce")) abort(401, 'replayed nonce');
   Cache::put("ai_nonce:$nonce", true, now()->addSeconds(600));


   // (c) recompute and constant-time compare
   $canonical = implode("\n", [$method, $path, $bodyHash, $timestamp, $nonce]);
   $expected  = hash_hmac('sha256', $canonical, $secret);
   if (! hash_equals($expected, (string) $request->header('X-Signature'))) {
       abort(401, 'bad signature');
   }


   return $next($request);
}
```

The timestamp window **and** the nonce cache are both required — the window bounds
replay to a short period, the nonce blocks replay _within_ that window.

---

## 4. The appointments endpoint

### Route

```php
// routes/internal.php  — prefix /internal, middleware VerifyAiSignature, no user auth
Route::get('/patients/{patient}/appointments', [InternalAppointmentController::class, 'index']);
```

### Controller

```php
public function index(int $patient)
{
   $appointments = Appointment::where('patient_id', $patient)
       ->orderByDesc('scheduled_at')
       ->get();


   return response()->json([
       'appointments' => $appointments->map(fn ($a) => [
           'id'           => $a->id,
           'specialty'    => $a->specialty,             // free text
           'scheduled_at' => $a->scheduled_at->toIso8601String(),
           'status'       => $a->status,                // free text
       ]),
   ]);
}
```

### Required response shape

Must match [`PatientAppointments` / `AppointmentSummary`](../app/laravel/schemas.py):

```json
{
  "appointments": [
    {
      "id": 123,
      "specialty": "Cardiology",
      "scheduled_at": "2026-08-01T09:30:00+01:00",
      "status": "confirmed"
    }
  ]
}
```

Extra fields are ignored by the AI backend (Pydantic `extra="ignore"`), but the
envelope key `appointments` and the four listed keys must be present. An empty
list is valid and expected for a patient with no appointments.

---

## 5. Trust boundary — who is the patient?

This is the key change vs. the workaround, and the reason it is safe.

- In the workaround, iOS calls with the **user's token**, so Laravel authenticates
  the patient.
- In the target, the AI backend calls with an **HMAC service signature**. That
  proves _"this is the AI backend"_, **not** _"this is patient 42"_.

Identity is established at the AI backend (from the verified Sanctum/JWT principal)
and passed as the `{patient_id}` path segment. The AI backend **discards any
`patient_id` the model tries to supply** and uses only the trusted principal
(`ctx.patient_id` in [`laravel_tools.py`](../app/tools/laravel_tools.py)) — this is
the IDOR defense.

**Implications for Laravel:**

- Once the signature is valid, **trust the `{patient_id}` in the path.**
- Do **not** also try to authenticate a user token on `/internal` routes — there
  isn't one. The `/internal` prefix + signature middleware _is_ the auth.
- **Network-isolate `/internal`** — it must not be reachable from the public
  internet, only from the AI backend (internal VPC / service mesh). The AI backend
  reaches it via `LARAVEL_BASE_URL` (e.g. `http://laravel.internal`).

---

## 6. Config

The same secret must be set on both sides:

| Side       | Key                                                            |
| ---------- | -------------------------------------------------------------- |
| AI backend | `LARAVEL_S2S_SECRET` (see [`app/config.py`](../app/config.py)) |
| Laravel    | `config('services.ai_backend.s2s_secret')` from a `.env` value |

Also relevant on the AI backend: `LARAVEL_BASE_URL`, `LARAVEL_TIMEOUT_SECONDS`.

---

## 7. End-to-end trace: "what are my appointments?"

1. Patient types the message → iOS `POST /chatbot/turn`.
2. AI backend verifies the user's Sanctum token → `Principal(subject=42)`.
3. Model calls the `lookup_appointments` tool (no arguments).
4. Tool uses `ctx.patient_id = 42` → `GET /internal/patients/42/appointments`, HMAC-signed.
5. Laravel `VerifyAiSignature` passes → controller returns the JSON envelope.
6. AI backend streams it as `event: tool_result`, `tool: "lookup_appointments"`.
7. iOS decodes `LookupAppointmentsPayload` and renders the appointment card — **no
   direct Laravel call.**

---

## 8. Summary of Laravel work

| Piece                                      | Effort                                       | Reused for other endpoints?     |
| ------------------------------------------ | -------------------------------------------- | ------------------------------- |
| HMAC verify middleware                     | Medium — canonical string must be byte-exact | Yes — all `/internal` endpoints |
| Nonce/timestamp replay cache               | Small                                        | Yes                             |
| `GET /internal/patients/{id}/appointments` | Small                                        | This is the appointments case   |
| Network isolation of `/internal`           | Config / infra                               | Yes                             |
| Shared secret in `.env`                    | Trivial                                      | Yes                             |

The heavy, reusable lift is the **signature middleware**. Build it once for the
appointments case and the remaining internal endpoints become route + controller +
matching JSON each.

---

## 9. Other internal endpoints (same pattern, for later)

All defined in [`app/laravel/client.py`](../app/laravel/client.py) /
[`schemas.py`](../app/laravel/schemas.py). Each needs the same signature middleware
plus a route/controller returning the documented shape.

| #   | Method & path                                | Purpose                                   | Response schema       |
| --- | -------------------------------------------- | ----------------------------------------- | --------------------- |
| 1   | `GET /internal/appointments/{id}`            | Appointment context for intake/follow-up  | `AppointmentContext`  |
| 2   | `GET /internal/patients/{id}/appointments`   | **Chatbot appointment lookup (this doc)** | `PatientAppointments` |
| 3   | `POST /internal/patients/{id}/reminders`     | Create medication reminder                | `ReminderCreated`     |
| 4   | `POST /internal/appointments/booking-intent` | Route into Laravel booking flow           | `BookingIntentResult` |
| 5   | `GET /internal/knowledge-base`               | FAQ/KB corpus for RAG ingestion           | `KnowledgeBase`       |

> Note: endpoint 4 (`booking-intent`) is partly superseded for the in-chat booking
> flow by the client-side `prepare_booking` card — see
> [`booking-in-chat.md`](./booking-in-chat.md). It remains listed here for the
> non-chat routing path.
