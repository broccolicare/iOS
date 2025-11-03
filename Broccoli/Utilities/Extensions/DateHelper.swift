//
//  DateHelper.swift
//  Broccoli
//
//  Created by AI Assistant on 02/11/25.
//

import Foundation

struct DateHelper {
    
    /// Returns a time-based greeting message based on the current hour
    /// - Returns: "Good morning!", "Good afternoon!", "Good evening!", or "Hello"
    static func greetingText() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        case 17..<22:
            return "Good evening!"
        default:
            return "Hello"
        }
    }
}
