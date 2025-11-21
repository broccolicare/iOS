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
    // add routes as needed
}
