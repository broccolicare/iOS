//
//  PushNotificationService.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

public protocol PushNotificationServiceProtocol {
    func requestPermission() async throws -> Bool
    func registerForRemoteNotifications()
    func handleNotification(_ userInfo: [AnyHashable: Any])
    func updateFCMToken() async throws
}

public class PushNotificationService: NSObject, PushNotificationServiceProtocol {
    private let secureStore: SecureStoreProtocol
    private let httpClient: HTTPClientProtocol
    
    public init(secureStore: SecureStoreProtocol, httpClient: HTTPClientProtocol) {
        self.secureStore = secureStore
        self.httpClient = httpClient
        super.init()
    }
    
    public func requestPermission() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
        return granted
    }
    
    public func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    public func handleNotification(_ userInfo: [AnyHashable: Any]) {
        // Handle notification payload
        if let appointmentId = userInfo["appointment_id"] as? String {
            // Navigate to appointment
            NotificationCenter.default.post(
                name: .navigateToAppointment,
                object: appointmentId
            )
        }
    }
    
    public func updateFCMToken() async throws {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            throw PushNotificationError.tokenNotAvailable
        }
        
        try secureStore.store(fcmToken, for: SecureStore.Keys.fcmToken)
        
        // Send token to your backend
        // TODO: Implement API call to update FCM token
    }
}

public enum PushNotificationError: Error {
    case tokenNotAvailable
    case permissionDenied
}

// MARK: - Notification Names
public extension Notification.Name {
    static let navigateToAppointment = Notification.Name("navigateToAppointment")
    static let newMessage = Notification.Name("newMessage")
}
