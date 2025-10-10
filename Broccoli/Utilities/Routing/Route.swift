//
//  Route.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//


enum Route: Hashable {
    case welcome
    case login
    case signup(origin: SignUpOrigin)
    case home
    case profile(userId: String)
    case booking(id: String)
    // add routes as needed
}