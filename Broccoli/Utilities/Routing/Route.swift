//
//  Route.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//


enum Route: Hashable {
    case welcome
    case login
    case signup(origin: SignUpOrigin, userType: UserType)
    case home
    case profile
    case doctorProfile
    case patientProfileDetail
    case doctorProfileDetail
    case booking(id: String)
    case staticPage(type: StaticPageType)
    case otp(phoneDisplay: String, from: OTPSource)
    case signupSuccess
    case resetPassword(email: String, otp: String)
    case editPatientProfile
    case editDoctorProfile
    case gPAppointBookingForm
    case bookingConfirmation
    case specialistList(departmentId: String?)
    case specialistBookingForm
    case paymentSuccess(booking: BookingData?)
    case medicalTourismForm
    case cureFromDrugForm
    case notifications
    case myAppointments
    case myPrescriptions
    case myPharmacies
    case addPharmacy
    case editPharmacy(pharmacy: Pharmacy)
    case bookPrescription
    case prescriptionQuestions
    case selectPharmacy
    case prescriptionConfirmation
    case settings
    case contactUs
    case search
    case appointmentDetailForDoctor(booking: BookingData)
    case appointmentDetailForPatient(booking: BookingData)
    case doctorAppointmentHistory
    case videoCall(booking: BookingData, token: String, channelName: String, uid: UInt)
    case healthAssistant
    /// The pre-appointment questionnaire for one appointment. Carries the id only
    /// — the server re-checks that the appointment belongs to the caller, so the
    /// route is not a capability.
    case intake(appointmentId: Int, doctorName: String?)
    // add routes as needed
}
