//
//  ToastPresenterBinder.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//


//import SwiftUI
//import Toasts
//
///// Put one of these inside your root view (inside the `.installToast(...)` scope)
///// so it can pick up the `presentToast` environment value and hand it to ToastManager.
//struct ToastPresenterBinder: View {
//    @Environment(\.presentToast) private var presentToast
//
//    var body: some View {
//        // Invisible view, just used to capture the environment and configure the manager
//        Color.clear
//            .onAppear {
//                // configure the global manager so other layers can call it
//                ToastManager.shared.configure { toast in
//                    presentToast(toast)
//                }
//            }
//    }
//}
