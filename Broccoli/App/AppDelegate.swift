//
//  AppDelegate.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import UIKit
import Combine
import FirebaseCore
import FirebaseCrashlytics
import FirebaseMessaging

/// `ObservableObject` so `BroccoliApp` (via `@UIApplicationDelegateAdaptor`) can
/// observe `pendingFollowUpBookingId` and route once both it and an authenticated
/// session are available — the two can arrive in either order, and this class has
/// no view/router of its own to route with directly.
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    /// Set from a tapped `ai_followup_checkin` notification — cold-start
    /// (`launchOptions`) or warm/background (`didReceive response:`). Consumed and
    /// cleared by `BroccoliApp.consumePendingFollowUpDeepLink()`.
    @Published var pendingFollowUpBookingId: Int?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        // Configure Firebase
        FirebaseApp.configure()

        // Set up push notifications
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Register for remote notifications on every launch — Apple requires this
        // regardless of prior permission state so the APNS token stays fresh.
        DispatchQueue.main.async {
            application.registerForRemoteNotifications()
        }

        // Request notification permissions (first-time prompt)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }

        // App launched by tapping a notification while fully killed — `didReceive
        // response:` below never fires for this case, so the payload only shows up
        // here.
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any],
           let bookingId = Self.followUpBookingId(from: remoteNotification) {
            pendingFollowUpBookingId = bookingId
        }

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Payload shape isn't pinned down on the client side (Laravel owns the FCM
    /// send), so this checks both a flat key and a nested `data` dict, and both
    /// `type` and `notification_type` as the type-marker key.
    static func followUpBookingId(from userInfo: [AnyHashable: Any]) -> Int? {
        func asInt(_ value: Any?) -> Int? {
            if let intValue = value as? Int { return intValue }
            if let stringValue = value as? String { return Int(stringValue) }
            return nil
        }

        let nested = userInfo["data"] as? [AnyHashable: Any]

        let type = (userInfo["type"] as? String)
            ?? (userInfo["notification_type"] as? String)
            ?? (nested?["type"] as? String)
            ?? (nested?["notification_type"] as? String)
        guard type?.lowercased() == "ai_followup_checkin" else { return nil }

        return asInt(userInfo["booking_id"]) ?? asInt(nested?["booking_id"])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .list, .badge, .sound])
        } else {
            completionHandler([.alert, .badge, .sound])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if let bookingId = Self.followUpBookingId(from: userInfo) {
            pendingFollowUpBookingId = bookingId
        }
        completionHandler()
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Firebase registration token: \(fcmToken)")
        
        // Notify the app so it can upload the token if a user is logged in
        NotificationCenter.default.post(name: .fcmTokenRefreshed, object: fcmToken)
    }
}
