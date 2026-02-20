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
    
    // Publishers for state changes
    public let remoteUserJoinedPublisher = PassthroughSubject<UInt, Never>()
    public let remoteUserLeftPublisher = PassthroughSubject<UInt, Never>()
    public let connectionStateChangedPublisher = PassthroughSubject<(AgoraConnectionState, AgoraConnectionChangedReason), Never>()
    public let networkQualityPublisher = PassthroughSubject<(UInt, AgoraNetworkQuality, AgoraNetworkQuality), Never>()
    
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
        options.publishCameraTrack = true
        options.publishMicrophoneTrack = true
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = true
        options.clientRoleType = .broadcaster
        
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
    
    public func destroy() {
        agoraEngine?.stopPreview()
        agoraEngine?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
        agoraEngine = nil
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
        agoraEngine?.muteLocalVideoStream(isLocalVideoMuted)
        print("📹 [AgoraService] Local video muted: \(isLocalVideoMuted)")
        return isLocalVideoMuted
    }
    
    // MARK: - Video Setup
    
    public func setupLocalVideo(view: UIView) {
        let canvas = AgoraRtcVideoCanvas()
        canvas.uid = 0
        canvas.view = view
        canvas.renderMode = .hidden
        agoraEngine?.setupLocalVideo(canvas)
        print("✅ [AgoraService] Local video setup")
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
