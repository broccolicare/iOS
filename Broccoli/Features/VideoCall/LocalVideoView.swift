//
//  LocalVideoView.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import SwiftUI
import AgoraRtcKit

struct LocalVideoView: UIViewRepresentable {
    let agoraService: AgoraService
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        agoraService.setupLocalVideo(view: view)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
}
