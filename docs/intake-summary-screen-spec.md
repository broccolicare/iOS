# Intake Summary Screen — Cross-Platform Spec

How the iOS app fetches, structures, and renders the **Intake Summary** screen,
written up so Web and Android can implement an identical screen against the
same API.

Reference implementation: `Broccoli/Features/Doctor/IntakeSummaryView.swift`.

---

## 1. What this screen is

A **doctor-only, read-only** view of the AI-generated summary of a patient's
pre-appointment intake conversation. It is pushed from the doctor's
appointment-detail screen via a "View Intake Summary" button and shows:

- the processing **status** of the intake conversation, and
- once complete, a structured **clinical summary** (chief complaint, pain,
  medications, allergies, history, lifestyle, pregnancy, flags).

There is no patient-facing entry point, and the screen has no edit/confirm/send
actions — the only interactive elements are "back" and "retry on error".

---

## 2. API contract

```
GET /doctor/bookings/{bookingId}/intake-summary
Authorization: Bearer <token>
```

- No query params, no request body.
- `bookingId` is the numeric booking/appointment ID (`BookingData.id`).
- Standard app-wide envelope response:

```jsonc
{
  "success": true,
  "data": { /* IntakeSummaryData, see below */ },
  "message": null
}
```

If `success` is `false`, show `message` (fallback: `"Failed to fetch intake summary"`).
On a network/transport error, show the error's localized description.

### Response shape (`data`)

```jsonc
{
  "status": "completed",           // string, always present
  "summary": { ... } | null,       // IntakeSummaryDetails, see below
  "conversation": {                // present but NOT rendered on iOS today
    "id": 123,
    "created_at": "2026-08-30T10:00:00Z"
  } | null,
  "transcript": "..." | null       // raw string, NOT rendered on iOS today
}
```

> **Note for Web/Android:** `conversation` and `transcript` are parsed by the
> iOS client but never displayed. Treat them as reserved/future fields unless
> product asks for a transcript view — don't invent UI for them without
> checking with iOS/product first, to avoid platforms diverging.

### `summary` object (`IntakeSummaryDetails`)

| JSON key | Type | Notes |
|---|---|---|
| `chief_complaint` | string \| null | |
| `history_of_present_illness` | string \| null | |
| `pain` | object \| null | see below |
| `medications` | string[] \| null | |
| `allergies` | object \| null | see below |
| `relevant_history` | string[] \| null | |
| `family_history` | string[] \| null | |
| `lifestyle` | object \| null | see below |
| `pregnancy` | string \| null | e.g. `"not_applicable"`, `"first_trimester"` |
| `flags` | string[] \| null | |

**`pain` object:**

| JSON key | Type | Notes |
|---|---|---|
| `present` | boolean \| null | |
| `severity` | number \| string \| null | ⚠️ see coercion rule below |
| `location` | string \| null | |
| `character` | string \| null | |
| `onset` | string \| null | |

**`allergies` object:**

| JSON key | Type |
|---|---|
| `status` | string \| null |
| `items` | string[] \| null |

**`lifestyle` object:**

| JSON key | Type |
|---|---|
| `smoking` | string \| null |
| `alcohol` | string \| null |
| `notes` | string \| null |

### ⚠️ `pain.severity` type coercion (must replicate exactly)

The backend is inconsistent about the type of `pain.severity` — it may send a
JSON number (int or float) or a string. iOS normalizes it to a string on
decode: try `Int` → `String(int)`, else try `Double` → `String(double)`, else
take the raw `String`. So server `6` displays as `"6"`, `6.5` displays as
`"6.5"`, and `"moderate"` displays as `"moderate"`.

Web/Android should apply the same normalize-to-string coercion when parsing
this field, so displayed severity values match iOS exactly regardless of
which type the backend happens to send for a given record.

---

## 3. Client state machine

Three mutually exclusive states drive the whole screen body:

1. **Loading** — fetch in flight.
2. **Error** — fetch failed or returned `success: false`.
3. **Loaded** — `data` populated.

Fetch is triggered automatically when the screen appears (not lazily on
scroll or on a button press), using the booking ID passed in from navigation.
Every fetch attempt (including retry) clears any previous data/error first,
so the screen always shows the loading state again rather than flashing
stale content.

```
on screen appear:
  isFetching = true; errorMessage = null; summaryData = null
  try:
    response = GET /doctor/bookings/{bookingId}/intake-summary
    if response.success && response.data present:
      summaryData = response.data
    else:
      errorMessage = response.message ?? "Failed to fetch intake summary"
  catch networkError:
    errorMessage = networkError.description
  finally:
    isFetching = false
```

Retry (shown only in the error state) re-runs the exact same routine.

---

## 4. Screen layout (top to bottom)

1. **Header** — back button, centered title "Intake Summary", no OS nav bar
   (fully custom header, back button mirrored on the right as an invisible
   spacer for centering).
2. **Body** (scrollable), one of:
   - **Loading:** centered spinner, ~80pt/dp top padding.
   - **Error:** warning icon, error message text (centered), a "Retry" button.
   - **Loaded:** see §5.

## 5. Loaded content — section order & visibility rules

**Status row** — always shown first, regardless of completion state:
`"Status"` label on the left, a pill on the right showing the status value
formatted as Title Case with underscores replaced by spaces (e.g.
`in_progress` → `"In progress"`).

**If `status !== "completed"` OR `summary` is null/absent:** show an empty
state instead of any of the sections below — icon, "Intake summary not yet
available", and `"Status: {formatted status}"`. Do not attempt to render
partial summary data for a non-completed status even if some fields happen to
be present in the payload.

**If `status === "completed"` and `summary` is present**, render these
sections in this exact order, each with an icon + title, some conditionally
shown:

| # | Section | Icon (SF Symbol, for reference) | Shown when | Content |
|---|---|---|---|---|
| 1 | Chief Complaint | `stethoscope` | always | `summary.chief_complaint` or `"Not provided"` |
| 2 | History of Present Illness | `clock.arrow.circlepath` | always | `summary.history_of_present_illness` or `"Not provided"` |
| 3 | Pain | `bolt.heart` | `summary.pain` is non-null | if `pain.present === true`: labeled rows for Severity, Location, Character, Onset (each row hidden entirely if its value is null/empty); else: text `"No pain reported"` |
| 4 | Medications | `pills` | always | bullet list of `summary.medications` (see empty-list rule below) |
| 5 | Allergies | `allergens` | `summary.allergies` is non-null | status text (Title Case, underscores→spaces, fallback `"Unknown"`) then bullet list of `allergies.items` |
| 6 | Relevant History | `doc.text` | always | bullet list of `summary.relevant_history` |
| 7 | Family History | `person.2` | always | bullet list of `summary.family_history` |
| 8 | Lifestyle | `heart.text.square` | `summary.lifestyle` is non-null | labeled rows for Smoking, Alcohol; Notes row only if `lifestyle.notes` is non-null and non-empty |
| 9 | Pregnancy | `figure.and.child.holdinghands` | `summary.pregnancy` is non-null **and** not equal to the literal string `"not_applicable"` | value, Title Case, underscores→spaces |
| 10 | Flags | `flag` | `summary.flags` is non-null and non-empty | bullet list |

`"not_applicable"` is a backend sentinel string, not a generic "empty" check —
match it exactly (case-sensitive, underscore form) to decide whether to hide
the Pregnancy section.

---

## 6. Formatting rules

- **Snake_case → Title Case:** replace every `_` with a space, then title-case
  the result. Applied to: the status pill, the empty-state status line,
  `allergies.status`, `pregnancy`, and every labeled-row value (severity,
  location, character, onset, smoking, alcohol). Example: `chest_pain` →
  `"Chest pain"`.
- **Missing text fallback:** `chief_complaint` / `history_of_present_illness`
  → `"Not provided"` when null.
- **Missing allergy status fallback:** `"Unknown"` when `allergies.status` is
  null.
- **Bullet list empty-state:** if the array is null or has zero items, show
  `"None reported"` instead of a list. Otherwise render one `• {item}` line
  per entry.
- **Labeled row (label/value pair, e.g. "Severity: 6"):** if the value is
  null or empty, suppress the entire row (label included) — do not render a
  label with a blank or "N/A" value. Exception: fields the section already
  gates on non-null (e.g. Lifestyle Notes) still apply their own
  non-empty check before showing.
- **Pain "not present":** literal text `"No pain reported"` when
  `pain.present !== true` (i.e. also shown when `present` is `false` or
  null).
- No date, phone-number, or unit/pluralization formatting exists on this
  screen — there are no such fields in the current payload.

---

## 7. Navigation contract

- Entry point: a "View Intake Summary" button on the doctor's
  appointment-detail screen, visible for any booking.
- Navigating to this screen requires only the booking's numeric `id`; no
  other booking fields are used by this screen.
- Back action returns to the previous screen (appointment detail).

---

## 8. Out of scope / not implemented anywhere yet

- No editing, annotating, or confirming the summary from this screen.
- No transcript viewer, despite `transcript` being present in the API
  response.
- No patient-facing version of this screen.

If Web or Android plan to add any of the above, flag it first so iOS can
decide whether to add matching functionality — otherwise the three platforms
will diverge on what is meant to be one contract.
