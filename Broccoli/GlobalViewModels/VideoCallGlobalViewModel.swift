//
//  VideoCallGlobalViewModel.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import Foundation
import SwiftUI
import Combine
import AgoraRtcKit

// MARK: - Test Configuration
/// Set `isEnabled = true` to bypass the Agora token API entirely and use hard-coded credentials.
/// Flip it back to `false` before shipping to production.
public struct VideoCallTestConfig {
    /// Master switch. When `true`, no token endpoint is called.
    public static var isEnabled: Bool = false
    
    /// A valid temporary token generated from the Agora console for the test channel below.
    public static let token: String = "0064fa50bc791c84b3fb63717186dbc3adeIABN1ly313pS7u0S5b/yQH5+kF70Ry7rdOzzwmLX1e/fxHmdsCNjR2uTIgATpKM4UU2aaQQAAQDhCZlpAgDhCZlpAwDhCZlpBADhCZlp"
    
    /// Channel name to join in test mode. Must match the token above.
    public static let channelName: String = "test-channel-broccoli"
    
    /// UID to use in test mode. Use different values for doctor/patient on separate devices.
    public static let doctorUID: UInt = 2001
    public static let patientUID: UInt = 30
}

@MainActor
public class VideoCallGlobalViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var callState: CallState = .idle
    @Published public var remainingTime: Int = 1800 // 30 minutes in seconds
    @Published public var isLocalAudioMuted: Bool = false
    @Published public var isLocalVideoMuted: Bool = false
    @Published public var remoteUserIds: [UInt] = []
    @Published public var connectionQuality: NetworkQuality = .unknown
    @Published public var showDoctorNotesForm: Bool = false
    @Published public var doctorNotes: String = ""
    @Published public var isReconnecting: Bool = false
    @Published public var isRemoteVideoMuted: Bool = false
    @Published public var isRemoteAudioMuted: Bool = false
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    
    // MARK: - Private Properties
    public let agoraService: AgoraService
    private var bookingService: BookingServiceProtocol
    private var callTimer: Timer?
    private var currentBooking: BookingData?
    private var currentUserRole: UserType?
    private var reconnectAttempts: Int = 0
    private static let maxReconnectAttempts = 1
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Call State Enum
    public enum CallState {
        case idle
        case connecting
        case connected
        case disconnected
        case ended
    }
    
    // MARK: - Network Quality Enum
    public enum NetworkQuality {
        case unknown
        case excellent
        case good
        case poor
        case veryPoor
        case disconnected
        
        var color: Color {
            switch self {
            case .excellent, .good:
                return .green
            case .poor:
                return .orange
            case .veryPoor, .disconnected:
                return .red
            case .unknown:
                return .gray
            }
        }
    }
    
    // MARK: - Initialization
    
    public init(
        agoraService: AgoraService,
        bookingService: BookingServiceProtocol,
        userRole: UserType?
    ) {
        self.agoraService = agoraService
        self.bookingService = bookingService
        self.currentUserRole = userRole
        
        setupAgoraSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupAgoraSubscriptions() {
        // Subscribe to remote user joined events
        agoraService.remoteUserJoinedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uid in
                self?.handleRemoteUserJoined(uid: uid)
            }
            .store(in: &cancellables)
        
        // Subscribe to remote user left events
        agoraService.remoteUserLeftPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] uid in
                self?.handleRemoteUserLeft(uid: uid)
            }
            .store(in: &cancellables)
        
        // Subscribe to connection state changes
        agoraService.connectionStateChangedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (state, reason) in
                self?.handleConnectionStateChanged(state: state, reason: reason)
            }
            .store(in: &cancellables)
        
        // Subscribe to network quality updates
        agoraService.networkQualityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (uid, txQuality, rxQuality) in
                self?.handleNetworkQuality(uid: uid, txQuality: txQuality, rxQuality: rxQuality)
            }
            .store(in: &cancellables)
        
        // Subscribe to token-about-to-expire events — renewToken before the channel is kicked
        agoraService.tokenPrivilegeWillExpirePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self else { return }
                Task { await self.renewTokenInBackground() }
            }
            .store(in: &cancellables)
        
        // Track remote video mute state so the UI can show a placeholder
        agoraService.remoteVideoMutedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_, muted) in
                self?.isRemoteVideoMuted = muted
            }
            .store(in: &cancellables)
        
        // Track remote audio mute state so the UI can show a mute badge
        agoraService.remoteAudioMutedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (_, muted) in
                self?.isRemoteAudioMuted = muted
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Call Management
    
    public func startCall(booking: BookingData, token: String, channelName: String, uid: UInt) async {
        self.currentBooking = booking
        self.callState = .connecting  // reset from any previous .ended/.idle state
        
        do {
            // Initialize Agora engine
            agoraService.initializeEngine()
            
            // Join channel
            try await agoraService.joinChannel(token: token, channelName: channelName, uid: uid)
            
            self.callState = .connected
            
            // Start call timer
            startCallTimer()
            
            // Notify backend that we have joined the channel (fire-and-forget)
            Task {
                do {
                    _ = try await bookingService.notifyJoined(bookingId: booking.id)
                    print("✅ [VideoCallVM] Joined presence notified for booking \(booking.id)")
                } catch {
                    print("⚠️ [VideoCallVM] Failed to notify joined presence: \(error)")
                }
            }
            
            print("✅ [VideoCallVM] Call started successfully")
        } catch {
            self.callState = .disconnected
            self.errorMessage = "Failed to start call: \(error.localizedDescription)"
            self.showErrorAlert = true
            print("❌ [VideoCallVM] Failed to start call: \(error)")
        }
    }
    
    /// Ends the call. For the doctor role, the API is called **first**; the
    /// channel is only left and the call torn down if the API succeeds.
    /// Returns `true` on clean termination, `false` if the API rejected the request.
    @discardableResult
    public func endCall(withNotes notes: String? = nil) async -> Bool {
        guard let booking = currentBooking else {
            print("⚠️ [VideoCallVM] No active booking to end")
            return false
        }
        
        // Doctor path: call API first — only end the call if it succeeds
        if currentUserRole == .doctor, let notes = notes, !notes.isEmpty {
            do {
                _ = try await bookingService.endConsultation(
                    bookingId: booking.id,
                    consultationNotes: notes
                )
                print("✅ [VideoCallVM] Consultation ended successfully")
            } catch {
                self.errorMessage = "Failed to end consultation: \(error.localizedDescription)"
                self.showErrorAlert = true
                print("❌ [VideoCallVM] endConsultation API failed: \(error)")
                return false
            }
        }
        
        // API succeeded (or patient path — no API needed)
        stopCallTimer()
        agoraService.leaveChannel()
        callState = .ended
        cleanup()
        return true
    }
    
    public func reconnectToCall() async {
        guard let booking = currentBooking else {
            print("⚠️ [VideoCallVM] No booking to reconnect")
            return
        }
        
        isReconnecting = true
        
        do {
            // Generate new token
            let channelName = booking.agoraSessionId ?? "booking_\(booking.id)_\(Int(Date().timeIntervalSince1970))"
            let tokenResponse = try await bookingService.generateAgoraToken(bookingId: booking.id, channelName: channelName, expireSeconds: 86400)
            
            guard let token = tokenResponse.token,
                  let channel = tokenResponse.channelName,
                  let uid = tokenResponse.uid else {
                throw NSError(domain: "Agora", code: -1, userInfo: [NSLocalizedDescriptionKey: tokenResponse.message ?? "Failed to generate token"])
            }
            
            // Rejoin channel
            try await agoraService.joinChannel(
                token: token,
                channelName: channel,
                uid: uid
            )
            
            self.callState = .connected
            self.isReconnecting = false
            
            // Resume timer if not expired
            if remainingTime > 0 {
                startCallTimer()
            }
            
            print("✅ [VideoCallVM] Reconnected successfully")
        } catch {
            self.isReconnecting = false
            self.errorMessage = "Failed to reconnect: \(error.localizedDescription)"
            self.showErrorAlert = true
            print("❌ [VideoCallVM] Reconnection failed: \(error)")
        }
    }
    
    // Proactive token refresh called 30 s before privilege expiry
    private func renewTokenInBackground() async {
        guard let booking = currentBooking else { return }
        do {
            let channelName = booking.agoraSessionId ?? "booking_\(booking.id)"
            let tokenResponse = try await bookingService.generateAgoraToken(bookingId: booking.id, channelName: channelName, expireSeconds: 3600)
            guard let newToken = tokenResponse.token else { return }
            agoraService.renewToken(newToken)
            print("🔑 [VideoCallVM] Token renewed proactively")
        } catch {
            print("⚠️ [VideoCallVM] Proactive token renewal failed: \(error)")
        }
    }
    
    // MARK: - Audio/Video Controls
    
    public func toggleLocalAudio() {
        isLocalAudioMuted = agoraService.toggleLocalAudio()
    }
    
    public func toggleLocalVideo() {
        isLocalVideoMuted = agoraService.toggleLocalVideo()
    }
    
    public func setupLocalVideo(view: UIView) {
        agoraService.setupLocalVideo(view: view)
    }
    
    public func setupRemoteVideo(view: UIView, uid: UInt) {
        agoraService.setupRemoteVideo(view: view, uid: uid)
    }
    
    // MARK: - Timer Management
    
    private func startCallTimer() {
        callTimer?.invalidate()
        
        callTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.remainingTime -= 1
                
                if self.remainingTime <= 0 {
                    self.handleTimerExpired()
                }
            }
        }
    }
    
    private func stopCallTimer() {
        callTimer?.invalidate()
        callTimer = nil
    }
    
    private func handleTimerExpired() {
        stopCallTimer()
        
        // Doctor: Show notes form
        if currentUserRole == .doctor {
            showDoctorNotesForm = true
            agoraService.leaveChannel()
        } else {
            // Patient: Auto-end and navigate back
            Task {
                await endCall()
            }
        }
        
        print("⏰ [VideoCallVM] Call timer expired")
    }
    
    // MARK: - Event Handlers
    
    private func handleRemoteUserJoined(uid: UInt) {
        if !remoteUserIds.contains(uid) {
            remoteUserIds.append(uid)
        }
        print("👤 [VideoCallVM] Remote user joined: \(uid)")
    }
    
    private func handleRemoteUserLeft(uid: UInt) {
        remoteUserIds.removeAll { $0 == uid }
        print("👤 [VideoCallVM] Remote user left: \(uid)")
        
        guard !remoteUserIds.isEmpty else {
            switch currentUserRole {
            case .patient:
                // Doctor (host) left — automatically end the patient's side of the call.
                print("👤 [VideoCallVM] Doctor (host) left — ending call on patient side")
                Task { await endCall() }
            case .doctor:
                // Patient left early — keep timer running, wait for rejoin or expiry.
                print("👤 [VideoCallVM] Patient left, keeping call active until timer expiry")
            default:
                break
            }
            return
        }
    }
    
    private func handleConnectionStateChanged(state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        // If the call has already been ended (e.g. host left and patient is cleaning up),
        // ignore any further SDK connection events so the reconnecting overlay never appears.
        guard callState != .ended else { return }

        switch state {
        case .connected:
            callState = .connected
            isReconnecting = false
            reconnectAttempts = 0  // Reset on successful connection
        case .disconnected:
            callState = .disconnected
            isReconnecting = true
        case .reconnecting:
            isReconnecting = true
        case .failed:
            // reason 8 = tokenExpired/invalidToken — attempt one automatic rejoin with a fresh token
            if reason == .reasonTokenExpired, reconnectAttempts < Self.maxReconnectAttempts {
                reconnectAttempts += 1
                print("🔑 [VideoCallVM] Token rejected by Agora cloud (reason: \(reason.rawValue)) — attempting token renewal (\(reconnectAttempts)/\(Self.maxReconnectAttempts))")
                Task { await reconnectToCall() }
            } else {
                callState = .disconnected
                let detail = reason == .reasonTokenExpired
                    ? "Token validation failed. Please check your Agora App Certificate configuration."
                    : "Connection failed. Please check your network and try again."
                errorMessage = detail
                showErrorAlert = true
            }
        case .connecting:
            callState = .connecting
        @unknown default:
            break
        }
    }
    
    private func handleNetworkQuality(uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        // Use the worse of the two qualities
        let quality = min(txQuality.rawValue, rxQuality.rawValue)
        
        switch quality {
        case 0:
            connectionQuality = .unknown
        case 1:
            connectionQuality = .excellent
        case 2:
            connectionQuality = .good
        case 3:
            connectionQuality = .poor
        case 4, 5:
            connectionQuality = .veryPoor
        case 6:
            connectionQuality = .disconnected
        default:
            connectionQuality = .unknown
        }
    }
    
    // MARK: - Cleanup
    
    private func cleanup() {
        stopCallTimer()
        remoteUserIds.removeAll()
        currentBooking = nil
        doctorNotes = ""
        showDoctorNotesForm = false
        remainingTime = 1800
        isLocalAudioMuted = false
        isLocalVideoMuted = false
        isRemoteVideoMuted = false
        isRemoteAudioMuted = false
        // NOTE: callState is intentionally NOT reset to .idle here.
        // Resetting it synchronously inside endCall() would coalesce with
        // callState = .ended in the same @MainActor batch, causing SwiftUI's
        // onChange(of: callState) to skip the .ended value entirely.
        // callState is reset to .connecting at the start of the next startCall().
        reconnectAttempts = 0
    }
    
    deinit {
        // Clean up resources - deinit is not MainActor isolated
        // Timer cleanup and service destroy can be done here
        callTimer?.invalidate()
        callTimer = nil
        agoraService.destroy()
    }
}
