//
//  CrashlyticsLogger.swift
//  Broccoli
//

import Foundation
import FirebaseCrashlytics

/// Thin wrapper around FirebaseCrashlytics for structured crash reporting.
enum CrashlyticsLogger {

    // MARK: - User Identity

    /// Call after a successful login to associate crashes with a user.
    static func setUser(id: String, email: String? = nil, name: String? = nil) {
        Crashlytics.crashlytics().setUserID(id)
        if let email { Crashlytics.crashlytics().setCustomValue(email, forKey: "email") }
        if let name  { Crashlytics.crashlytics().setCustomValue(name,  forKey: "name")  }
    }

    /// Call on logout to clear user identity.
    static func clearUser() {
        Crashlytics.crashlytics().setUserID("")
        Crashlytics.crashlytics().setCustomValue("", forKey: "email")
        Crashlytics.crashlytics().setCustomValue("", forKey: "name")
    }

    // MARK: - Custom Keys (breadcrumbs)

    /// Attach an arbitrary key-value pair visible in the crash report.
    static func set(_ value: String, forKey key: String) {
        Crashlytics.crashlytics().setCustomValue(value, forKey: key)
    }

    // MARK: - Non-fatal Errors

    /// Record a non-fatal error (e.g. a failed network call) without crashing.
    static func record(_ error: Error, context: String? = nil) {
        var userInfo: [String: Any] = [:]
        if let context { userInfo["context"] = context }
        let wrapped = NSError(
            domain: (error as NSError).domain,
            code: (error as NSError).code,
            userInfo: userInfo.merging((error as NSError).userInfo) { new, _ in new }
        )
        Crashlytics.crashlytics().record(error: wrapped)
    }

    /// Log a plain message that appears in the Crashlytics log tab (not a crash).
    static func log(_ message: String) {
        Crashlytics.crashlytics().log(message)
    }
}
