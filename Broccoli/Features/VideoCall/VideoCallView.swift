//
//  VideoCallView.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import SwiftUI

struct VideoCallView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authVM: AuthGlobalViewModel
    @StateObject private var videoCallVM: VideoCallGlobalViewModel
    
    let booking: BookingData
    let token: String
    let channelName: String
    let uid: UInt
    
    init(booking: BookingData, token: String, channelName: String, uid: UInt, 
         agoraService: AgoraService, bookingService: BookingServiceProtocol, userRole: UserType?) {
        self.booking = booking
        self.token = token
        self.channelName = channelName
        self.uid = uid
        
        _videoCallVM = StateObject(wrappedValue: VideoCallGlobalViewModel(
            agoraService: agoraService,
            bookingService: bookingService,
            userRole: userRole
        ))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Remote video (full screen)
            if let remoteUid = videoCallVM.remoteUserIds.first {
                ZStack {
                    RemoteVideoView(agoraService: videoCallVM.agoraService, uid: remoteUid)
                        .ignoresSafeArea()
                        // Hide the stale last-frame when remote user turns camera off
                        .opacity(videoCallVM.isRemoteVideoMuted ? 0 : 1)
                    
                    if videoCallVM.isRemoteVideoMuted {
                        cameraOffPlaceholder(label: "Camera is off")
                            .ignoresSafeArea()
                    }
                    
                    // Mute badge — bottom-left of the full-screen remote feed
                    if videoCallVM.isRemoteAudioMuted {
                        VStack {
                            Spacer()
                            HStack {
                                muteBadge()
                                    .padding(.leading, 16)
                                    .padding(.bottom, 160) // sits above the control bar
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                // Waiting for remote user
                VStack(spacing: theme.spacing.lg) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Waiting for other participant...")
                        .font(theme.typography.subtitle)
                        .foregroundStyle(.white)
                }
            }
            
            // Local video (floating PiP)
            VStack {
                HStack {
                    Spacer()
                    ZStack(alignment: .bottomLeading) {
                        LocalVideoView(agoraService: videoCallVM.agoraService)
                            // Hide stale last-frame when local camera is off
                            .opacity(videoCallVM.isLocalVideoMuted ? 0 : 1)
                        
                        if videoCallVM.isLocalVideoMuted {
                            cameraOffPlaceholder(label: "Your camera is off")
                                .cornerRadius(12)
                        }
                        
                        // Mute badge — bottom-left corner of the local PiP
                        if videoCallVM.isLocalAudioMuted {
                            muteBadge()
                                .padding(6)
                        }
                    }
                    .frame(width: 120, height: 160)
                    .cornerRadius(12)
                    .shadow(radius: 10)
                    .padding(theme.spacing.md)
                }
                Spacer()
            }
            
            // Top bar with timer and network quality
            VStack {
                HStack {
                    // Timer
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.white)
                        Text(formatTime(videoCallVM.remainingTime))
                            .font(theme.typography.medium16)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, theme.spacing.md)
                    .padding(.vertical, theme.spacing.sm)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    
                    Spacer()
                    
                    // Network quality indicator
                    Circle()
                        .fill(videoCallVM.connectionQuality.color)
                        .frame(width: 12, height: 12)
                        .padding(.horizontal, theme.spacing.md)
                        .padding(.vertical, theme.spacing.sm)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                }
                .padding(theme.spacing.md)
                
                Spacer()
            }
            
            // Bottom control bar
            VStack {
                Spacer()
                
                HStack(spacing: theme.spacing.xl) {
                    // Mute audio button
                    Button(action: {
                        Task { @MainActor in videoCallVM.toggleLocalAudio() }
                    }) {
                        ZStack {
                            Circle()
                                .fill(videoCallVM.isLocalAudioMuted ? Color.red : Color.white.opacity(0.3))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: videoCallVM.isLocalAudioMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // End call button
                    Button(action: {
                        handleEndCallTapped()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white)
                        }
                    }
                    
                    // Toggle video button
                    Button(action: {
                        Task { @MainActor in videoCallVM.toggleLocalVideo() }
                    }) {
                        ZStack {
                            Circle()
                                .fill(videoCallVM.isLocalVideoMuted ? Color.red : Color.white.opacity(0.3))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: videoCallVM.isLocalVideoMuted ? "video.slash.fill" : "video.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Reconnecting overlay
            if videoCallVM.isReconnecting {
                VStack(spacing: theme.spacing.md) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Reconnecting...")
                        .font(theme.typography.subtitle)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
            }
            
            // Doctor notes form overlay
            if videoCallVM.showDoctorNotesForm {
                DoctorNotesFormView(
                    notes: $videoCallVM.doctorNotes,
                    isPresented: $videoCallVM.showDoctorNotesForm,
                    onEndCall: { notes in
                        Task {
                            await videoCallVM.endCall(withNotes: notes)
                            router.pop()
                        }
                    }
                )
            }
        }
        .navigationBarHidden(true)
        // When the doctor (host) ends the call, the patient's callState becomes .ended.
        // Navigate back automatically so they are never stuck on the reconnecting overlay.
        .onChange(of: videoCallVM.callState) { state in
            if state == .ended, authVM.currentUser?.primaryRole != .doctor {
                router.pop()
            }
        }
        .task {
            await videoCallVM.startCall(booking: booking, token: token, channelName: channelName, uid: uid)
        }
        .alert("Error", isPresented: $videoCallVM.showErrorAlert) {
            Button("OK") {
                router.pop()
            }
        } message: {
            if let errorMessage = videoCallVM.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleEndCallTapped() {
        if authVM.currentUser?.primaryRole == .doctor {
            // Show notes form for doctor
            videoCallVM.showDoctorNotesForm = true
        } else {
            // Patient can end immediately
            Task {
                await videoCallVM.endCall()
                router.pop()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    // MARK: - Mute Badge
    
    @ViewBuilder
    private func muteBadge() -> some View {
        HStack(spacing: 4) {
            Image(systemName: "mic.slash.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.red.opacity(0.85))
        .clipShape(Capsule())
    }
    
    // MARK: - Placeholder View
    
    @ViewBuilder
    private func cameraOffPlaceholder(label: String) -> some View {
        ZStack {
            Color(white: 0.12)
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 64, height: 64)
                    Image(systemName: "video.slash.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}
