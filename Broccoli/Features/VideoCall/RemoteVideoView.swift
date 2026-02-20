//
//  RemoteVideoView.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import SwiftUI
import AgoraRtcKit

struct RemoteVideoView: UIViewRepresentable {
    let agoraService: AgoraService
    let uid: UInt
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        agoraService.setupRemoteVideo(view: view, uid: uid)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
