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
    @Published public var errorMessage: String?
    @Published public var showErrorAlert: Bool = false
    
    // MARK: - Private Properties
    public let agoraService: AgoraService
    private var bookingService: BookingServiceProtocol
    private var callTimer: Timer?
    private var currentBooking: BookingData?
    private var currentUserRole: UserType?
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
    }
    
    // MARK: - Call Management
    
    public func startCall(booking: BookingData, token: String, channelName: String, uid: UInt) async {
        self.currentBooking = booking
        self.callState = .connecting
        
        do {
            // Initialize Agora engine
            agoraService.initializeEngine()
            
            // Join channel
            try await agoraService.joinChannel(token: token, channelName: channelName, uid: uid)
            
            self.callState = .connected
            
            // Start call timer
            startCallTimer()
            
            print("✅ [VideoCallVM] Call started successfully")
        } catch {
            self.callState = .disconnected
            self.errorMessage = "Failed to start call: \(error.localizedDescription)"
            self.showErrorAlert = true
            print("❌ [VideoCallVM] Failed to start call: \(error)")
        }
    }
    
    public func endCall(withNotes notes: String? = nil) async {
        guard let booking = currentBooking else {
            print("⚠️ [VideoCallVM] No active booking to end")
            return
        }
        
        // Stop timer
        stopCallTimer()
        
        // Leave Agora channel
        agoraService.leaveChannel()
        
        // Update call state
        callState = .ended
        
        // If doctor and notes provided, send to backend
        if currentUserRole == .doctor, let notes = notes, !notes.isEmpty {
            do {
                _ = try await bookingService.endVideoCall(bookingId: booking.id, notes: notes)
                print("✅ [VideoCallVM] Call ended with notes")
            } catch {
                self.errorMessage = "Failed to save notes: \(error.localizedDescription)"
                self.showErrorAlert = true
                print("❌ [VideoCallVM] Failed to end call: \(error)")
            }
        }
        
        // Clean up
        cleanup()
    }
    
    public func reconnectToCall() async {
        guard let booking = currentBooking else {
            print("⚠️ [VideoCallVM] No booking to reconnect")
            return
        }
        
        isReconnecting = true
        
        do {
            // Generate new token
            let tokenResponse = try await bookingService.generateAgoraToken(bookingId: booking.id)
            
            // Rejoin channel
            try await agoraService.joinChannel(
                token: tokenResponse.token,
                channelName: tokenResponse.channelName,
                uid: tokenResponse.uid
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
        
        // If patient leaves early and we're doctor, keep call active
        if currentUserRole == .doctor && remoteUserIds.isEmpty {
            // Show message that patient left, but keep timer running
            print("👤 [VideoCallVM] Patient left, waiting for rejoin or timer expiry")
        }
    }
    
    private func handleConnectionStateChanged(state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        switch state {
        case .connected:
            callState = .connected
            isReconnecting = false
        case .disconnected:
            callState = .disconnected
            // Try to reconnect on network issues
            isReconnecting = true
        case .reconnecting:
            isReconnecting = true
        case .failed:
            callState = .disconnected
            errorMessage = "Connection failed"
            showErrorAlert = true
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
        callState = .idle
    }
    
    deinit {
        // Clean up resources - deinit is not MainActor isolated
        // Timer cleanup and service destroy can be done here
        callTimer?.invalidate()
        callTimer = nil
        agoraService.destroy()
    }
}
