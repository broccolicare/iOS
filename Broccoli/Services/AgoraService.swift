//
//  AgoraService.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import Foundation
import AgoraRtcKit
import Combine

// MARK: - Agora Service Protocol
public protocol AgoraServiceProtocol {
    func initializeEngine()
    func joinChannel(token: String, channelName: String, uid: UInt) async throws
    func leaveChannel()
    func renewToken(_ token: String)
    func destroy()
    func toggleLocalAudio() -> Bool
    func toggleLocalVideo() -> Bool
    func setupLocalVideo(view: UIView)
    func setupRemoteVideo(view: UIView, uid: UInt)
}

// MARK: - Agora Service
public final class AgoraService: NSObject, AgoraServiceProtocol {
    private var agoraEngine: AgoraRtcEngineKit?
    private let appId: String
    
    // Saved local video view so it can be re-registered after engine init
    private var pendingLocalVideoView: UIView?
    
    // Publishers for state changes
    public let remoteUserJoinedPublisher = PassthroughSubject<UInt, Never>()
    public let remoteUserLeftPublisher = PassthroughSubject<UInt, Never>()
    public let connectionStateChangedPublisher = PassthroughSubject<(AgoraConnectionState, AgoraConnectionChangedReason), Never>()
    public let networkQualityPublisher = PassthroughSubject<(UInt, AgoraNetworkQuality, AgoraNetworkQuality), Never>()
    public let tokenPrivilegeWillExpirePublisher = PassthroughSubject<Void, Never>()
    /// Fires whenever a remote user enables or disables their video stream.
    /// Payload: (uid, isMuted)
    public let remoteVideoMutedPublisher = PassthroughSubject<(UInt, Bool), Never>()
    /// Fires whenever a remote user mutes or unmutes their microphone.
    /// Payload: (uid, isMuted)
    public let remoteAudioMutedPublisher = PassthroughSubject<(UInt, Bool), Never>()
    
    private var isLocalAudioMuted: Bool = false
    private var isLocalVideoMuted: Bool = false
    
    public init(appId: String) {
        self.appId = appId
        super.init()
    }
    
    // MARK: - Engine Lifecycle
    
    public func initializeEngine() {
        guard agoraEngine == nil else {
            print("⚠️ [AgoraService] Engine already initialized")
            return
        }
        
        // Create Agora engine instance
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .communication
        config.areaCode = .global
        
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        
        // Enable video module
        agoraEngine?.enableVideo()
        agoraEngine?.enableAudio()
        
        // Configure video encoder
        let videoConfig = AgoraVideoEncoderConfiguration(
            size: AgoraVideoDimension640x360,
            frameRate: 15,
            bitrate: AgoraVideoBitrateStandard,
            orientationMode: .adaptative,
            mirrorMode: .auto
        )
        agoraEngine?.setVideoEncoderConfiguration(videoConfig)
        
        // Set channel profile to communication (1-to-1 or small group)
        agoraEngine?.setChannelProfile(.communication)
        
        // Set client role to broadcaster (both can send/receive)
        agoraEngine?.setClientRole(.broadcaster)
        
        // Re-apply local video canvas if the view was registered before engine init
        if let view = pendingLocalVideoView {
            let canvas = AgoraRtcVideoCanvas()
            canvas.uid = 0
            canvas.view = view
            canvas.renderMode = .hidden
            agoraEngine?.setupLocalVideo(canvas)
            pendingLocalVideoView = nil
        }
        
        print("✅ [AgoraService] Engine initialized successfully")
    }
    
    public func joinChannel(token: String, channelName: String, uid: UInt) async throws {
        guard let engine = agoraEngine else {
            throw AgoraServiceError.engineNotInitialized
        }
        
        // Start preview before joining
        engine.startPreview()
        
        // Create media options
        let options = AgoraRtcChannelMediaOptions()
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        options.clientRoleType = .broadcaster
        
        // Simulator has no real camera — publishing camera track causes FigCaptureSource errors
        // and can trigger an SDK reconnect that exposes token validation failures
        #if targetEnvironment(simulator)
        options.publishCameraTrack = false
        #else
        options.publishCameraTrack = true
        #endif
        
        // Join channel
        let result = engine.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: uid,
            mediaOptions: options
        )
        
        if result != 0 {
            throw AgoraServiceError.joinChannelFailed(errorCode: result)
        }
        
        print("✅ [AgoraService] Joined channel: \(channelName) with UID: \(uid)")
    }
    
    public func leaveChannel() {
        agoraEngine?.stopPreview()
        agoraEngine?.leaveChannel(nil)
        print("✅ [AgoraService] Left channel")
    }
    
    public func renewToken(_ token: String) {
        agoraEngine?.renewToken(token)
        print("🔑 [AgoraService] Token renewed")
    }
    
    public func destroy() {
        agoraEngine?.stopPreview()
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        agoraEngine = nil
        pendingLocalVideoView = nil
        print("✅ [AgoraService] Engine destroyed")
    }
    
    // MARK: - Audio/Video Controls
    
    public func toggleLocalAudio() -> Bool {
        isLocalAudioMuted.toggle()
        agoraEngine?.muteLocalAudioStream(isLocalAudioMuted)
        print("🔊 [AgoraService] Local audio muted: \(isLocalAudioMuted)")
        return isLocalAudioMuted
    }
    
    public func toggleLocalVideo() -> Bool {
        isLocalVideoMuted.toggle()
        // enableLocalVideo(false) fully disables the camera capture device;
        // muteLocalVideoStream only blocks the outgoing stream but keeps the
        // camera running, which makes the button appear broken.
        agoraEngine?.enableLocalVideo(!isLocalVideoMuted)
        print("📹 [AgoraService] Local video enabled: \(!isLocalVideoMuted)")
        return isLocalVideoMuted
    }
    
    // MARK: - Video Setup
    
    public func setupLocalVideo(view: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = view
        canvas.renderMode = .hidden
        if agoraEngine != nil {
            agoraEngine?.setupLocalVideo(canvas)
            print("✅ [AgoraService] Local video setup")
        } else {
            // Engine not yet initialized — save view to re-register after initializeEngine()
            pendingLocalVideoView = view
            print("⏳ [AgoraService] Local video view saved, will register after engine init")
        }
    }
    
    public func setupRemoteVideo(view: UIView, uid: UInt) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = uid
        canvas.view = view
        canvas.renderMode = .hidden
        agoraEngine?.setupRemoteVideo(canvas)
        print("✅ [AgoraService] Remote video setup for UID: \(uid)")
    }
}

// MARK: - Agora RTC Engine Delegate

extension AgoraService: AgoraRtcEngineDelegate {
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("👤 [AgoraService] Remote user joined: \(uid)")
        remoteUserJoinedPublisher.send(uid)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("👤 [AgoraService] Remote user left: \(uid), reason: \(reason.rawValue)")
        remoteUserLeftPublisher.send(uid)
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, connectionChangedTo state: AgoraConnectionState, reason: AgoraConnectionChangedReason) {
        print("🔌 [AgoraService] Connection state changed to: \(state.rawValue), reason: \(reason.rawValue)")
        connectionStateChangedPublisher.send((state, reason))
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, networkQuality uid: UInt, txQuality: AgoraNetworkQuality, rxQuality: AgoraNetworkQuality) {
        networkQualityPublisher.send((uid, txQuality, rxQuality))
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("❌ [AgoraService] Error occurred: \(errorCode.rawValue)")
    }
    
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("⚠️ [AgoraService] Warning: \(warningCode.rawValue)")
    }
    
    // Called ~30 seconds before the token expires — triggers proactive renewal
    public func rtcEngineTokenPrivilegeWillExpire(_ engine: AgoraRtcEngineKit, token: String) {
        print("🔑 [AgoraService] Token privilege will expire — requesting renewal")
        tokenPrivilegeWillExpirePublisher.send()
    }
    
    // Called when a remote user toggles their video stream on/off
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didVideoMuted muted: Bool, byUid uid: UInt) {
        print("📹 [AgoraService] Remote UID \(uid) video muted: \(muted)")
        remoteVideoMutedPublisher.send((uid, muted))
    }
    
    // Called when a remote user mutes or unmutes their microphone
    public func rtcEngine(_ engine: AgoraRtcEngineKit, didAudioMuted muted: Bool, byUid uid: UInt) {
        print("🔇 [AgoraService] Remote UID \(uid) audio muted: \(muted)")
        remoteAudioMutedPublisher.send((uid, muted))
    }
}

// MARK: - Agora Service Error

public enum AgoraServiceError: LocalizedError {
    case engineNotInitialized
    case joinChannelFailed(errorCode: Int32)
    
    public var errorDescription: String? {
        switch self {
        case .engineNotInitialized:
            return "Agora engine is not initialized. Please call initializeEngine() first."
        case .joinChannelFailed(let errorCode):
            return "Failed to join channel. Error code: \(errorCode)"
        }
    }
}
