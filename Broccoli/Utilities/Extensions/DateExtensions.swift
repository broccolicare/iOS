//
//  DateExtensions.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import Foundation

extension Date {
    /// Check if the current time is within the call window for a booking
    /// Call window: 5 minutes before appointment time until 30 minutes after
    /// - Parameters:
    ///   - appointmentDate: Date string in format "yyyy-MM-dd"
    ///   - appointmentTime: Time string in format "HH:mm" or "HH:mm:ss" (24-hour)
    ///   - callDurationMinutes: Duration of the call in minutes (default: 30)
    ///   - advanceMinutes: How many minutes before appointment the call button should appear (default: 5)
    /// - Returns: True if current time is within the call window
    static func isWithinCallWindow(
        appointmentDate: String,
        appointmentTime: String,
        callDurationMinutes: Int = 30,
        advanceMinutes: Int = 5
    ) -> Bool {
        // Parse appointment date and time
        guard let appointmentDateTime = parseDateAndTime(date: appointmentDate, time: appointmentTime) else {
            print("⚠️ [DateExtensions] Failed to parse date/time: \(appointmentDate) \(appointmentTime)")
            return false
        }
        
        let now = Date()
        
        // Calculate window bounds
        let windowStart = appointmentDateTime.addingTimeInterval(TimeInterval(-advanceMinutes * 60))
        let windowEnd = appointmentDateTime.addingTimeInterval(TimeInterval(callDurationMinutes * 60))
        
        let isWithinWindow = now >= windowStart && now <= windowEnd
        
        #if DEBUG
        print("🕐 [DateExtensions] Call Window Check:")
        print("   Now: \(now)")
        print("   Appointment: \(appointmentDateTime)")
        print("   Window Start: \(windowStart)")
        print("   Window End: \(windowEnd)")
        print("   Within Window: \(isWithinWindow)")
        #endif
        
        return isWithinWindow
    }
    
    /// Check if an appointment has ended (past the appointment time + duration)
    /// - Parameters:
    ///   - appointmentDate: Date string in format "yyyy-MM-dd"
    ///   - appointmentTime: Time string in format "HH:mm" or "HH:mm:ss" (24-hour)
    ///   - callDurationMinutes: Duration of the call in minutes (default: 30)
    /// - Returns: True if the appointment has ended
    static func hasAppointmentEnded(
        appointmentDate: String,
        appointmentTime: String,
        callDurationMinutes: Int = 30
    ) -> Bool {
        guard let appointmentDateTime = parseDateAndTime(date: appointmentDate, time: appointmentTime) else {
            return false
        }
        
        let appointmentEndTime = appointmentDateTime.addingTimeInterval(TimeInterval(callDurationMinutes * 60))
        let now = Date()
        
        return now > appointmentEndTime
    }
    
    /// Get human-readable time remaining until appointment
    /// - Parameters:
    ///   - appointmentDate: Date string in format "yyyy-MM-dd"
    ///   - appointmentTime: Time string in format "HH:mm" or "HH:mm:ss" (24-hour)
    /// - Returns: String like "in 2 hours" or "in 30 minutes", or nil if appointment has passed
    static func timeUntilAppointment(
        appointmentDate: String,
        appointmentTime: String
    ) -> String? {
        guard let appointmentDateTime = parseDateAndTime(date: appointmentDate, time: appointmentTime) else {
            return nil
        }
        
        let now = Date()
        let timeInterval = appointmentDateTime.timeIntervalSince(now)
        
        // If appointment has passed, return nil
        if timeInterval < 0 {
            return nil
        }
        
        let minutes = Int(timeInterval / 60)
        let hours = minutes / 60
        let days = hours / 24
        
        if days > 0 {
            return days == 1 ? "in 1 day" : "in \(days) days"
        } else if hours > 0 {
            return hours == 1 ? "in 1 hour" : "in \(hours) hours"
        } else if minutes > 0 {
            return minutes == 1 ? "in 1 minute" : "in \(minutes) minutes"
        } else {
            return "now"
        }
    }
    
    // MARK: - Private Helpers

    /// Returns true once the call window has opened (advanceMinutes before the appointment)
    /// and keeps returning true indefinitely — callers are responsible for checking
    /// whether the booking is complete.
    /// - Parameters:
    ///   - appointmentDate: Date string in format "yyyy-MM-dd"
    ///   - appointmentTime: Time string in format "HH:mm" or "HH:mm:ss"
    ///   - advanceMinutes: How many minutes before appointment the window opens (default: 5)
    /// - Returns: True if current time is at or past (appointmentTime − advanceMinutes)
    static func isCallWindowOpen(
        appointmentDate: String,
        appointmentTime: String,
        advanceMinutes: Int = 5
    ) -> Bool {
        guard let appointmentDateTime = parseDateAndTime(date: appointmentDate, time: appointmentTime) else {
            return false
        }
        let windowStart = appointmentDateTime.addingTimeInterval(TimeInterval(-advanceMinutes * 60))
        return Date() >= windowStart
    }
    
    /// Parse date and time strings into a Date object, supporting both HH:mm and HH:mm:ss formats
    /// - Parameters:
    ///   - date: Date string in format "yyyy-MM-dd"
    ///   - time: Time string in format "HH:mm" or "HH:mm:ss"
    /// - Returns: Date object or nil if parsing fails
    private static func parseDateAndTime(date: String, time: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        
        // Try with seconds first (HH:mm:ss)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateTimeWithSeconds = "\(date) \(time)"
        if let parsedDate = dateFormatter.date(from: dateTimeWithSeconds) {
            return parsedDate
        }
        
        // Try without seconds (HH:mm)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        return dateFormatter.date(from: dateTimeWithSeconds)
    }
}
