//
//  ChatBookingPrefill.swift
//  Broccoli
//
//  P4-04 — the Health Assistant → booking-form handoff.
//

import Foundation

/// Values carried from a `prepare_booking` card into the existing booking form.
///
/// ⚠️ **Why this exists rather than just setting the view model's fields directly:**
/// both booking forms call `resetBookingForm()` in `onAppear`
/// (`GPAppointmentBookingForm.swift:408`, `SpecialtyListView.swift:141`), which
/// wipes anything set before the push. This struct is parked on
/// `BookingGlobalViewModel.pendingChatPrefill`, which `resetBookingForm()`
/// deliberately does *not* clear, and is consumed by the form after it has reset
/// itself.
///
/// It is a suggestion, never a commitment — every field is optional and the form
/// stays fully editable. Chat saves taps; it does not book anything.
public struct ChatBookingPrefill: Equatable {
    /// `"1"`…`"4"`, matching `BookingGlobalViewModel.selectedDepartmentId`.
    public let departmentId: String
    /// `"1"` / `"0"`, matching `BookingGlobalViewModel.isGP`.
    public let isGP: String
    /// Resolved before the push; nil means the user still has to pick one.
    public let serviceId: Int?
    /// From `date_from`. A window's start, not an appointment time.
    public let preferredDate: Date?
    /// `morning` / `afternoon` / `evening`. `any` maps to nil — the form has no
    /// representation for it and it feeds `time_slot` on the booking request.
    public let timeSlotPeriod: String?
    /// The patient's own words, shown in the notes field so they don't retype it.
    public let reason: String?
    /// `HH:mm` — set only when the user tapped a specific time on the card, and
    /// still only a *suggestion*.
    ///
    /// 🛑 The form must apply this **after** its own `fetchAvailableTimeSlots()`
    /// and only if the time is still in the response. The card's times are
    /// advisory and nothing reserves them, so a slot taken in between must leave
    /// the user on an unselected form — never on a form showing a time the server
    /// would reject at confirmation.
    public let exactTime: String?

    public init(
        departmentId: String,
        isGP: String,
        serviceId: Int? = nil,
        preferredDate: Date? = nil,
        timeSlotPeriod: String? = nil,
        reason: String? = nil,
        exactTime: String? = nil
    ) {
        self.departmentId = departmentId
        self.isGP = isGP
        self.serviceId = serviceId
        self.preferredDate = preferredDate
        self.timeSlotPeriod = timeSlotPeriod
        self.reason = reason
        self.exactTime = exactTime
    }
}
