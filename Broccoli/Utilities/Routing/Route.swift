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
    case profile(userId: String)
    case booking(id: String)
    case staticPage(type: StaticPageType)
    case otp(phoneDisplay: String)
    case signupSuccess
    // add routes as needed
}
