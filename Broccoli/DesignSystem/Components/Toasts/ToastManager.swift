//
//  ToastManager.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//

//import SwiftUI
//import Toasts   // the package module, per README
//
//@MainActor
//final class ToastManager {
//    static let shared = ToastManager()
//    private init() {}
//
//    // the library exposes ToastValue, so presenter's type is (ToastValue) -> Void
//    private var presenter: ((ToastValue) -> Void)?
//
//    /// Call once to bind the environment presenter (see ToastPresenterBinder below)
//    func configure(presenter: @escaping (ToastValue) -> Void) {
//        self.presenter = presenter
//    }
//
//    // Generic / reusable helpers
//    func showError(_ message: String) {
//        let toast = ToastValue(icon: Image(systemName: "xmark.octagon"), message: message)
//        present(toast)
//    }
//
//    func showSuccess(_ message: String) {
//        let toast = ToastValue(icon: Image(systemName: "checkmark.circle"), message: message)
//        present(toast)
//    }
//
//    func showInfo(_ message: String) {
//        let toast = ToastValue(icon: Image(systemName: "info.circle"), message: message)
//        present(toast)
//    }
//
//    /// Generic method if you want custom icon / button etc.
//    func show(_ toast: ToastValue) {
//        present(toast)
//    }
//
//    // MARK: - Private
//    private func present(_ toast: ToastValue) {
//        guard let presenter = presenter else {
//            // fallback for devs: print so you don't silently lose messages
//            print("⚠️ ToastManager: presenter not configured. Toast message:")
//            return
//        }
//        presenter(toast)
//    }
//}
