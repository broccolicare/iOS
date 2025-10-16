//
//  OTPViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 16/10/25.
//


import Foundation
import Combine

@MainActor
final class OTPViewModel: ObservableObject {
    @Published var digits: [String] = Array(repeating: "", count: 6)
    @Published var showToast: Bool = false
    @Published var toastMessage: String = ""
    @Published var toastIsError: Bool = true

    // Resend cooldown (seconds)
    @Published var resendCountdown: Int = 60
    private var timerCancellable: AnyCancellable? = nil

    public init(digitsCount: Int = 6, countdown: Int = 60) {
        self.digits = Array(repeating: "", count: digitsCount)
        self.resendCountdown = countdown
        if countdown > 0 {
            startCountdown()
        }
    }

    // Combined OTP string
    var code: String {
        digits.joined()
    }

    var isValid: Bool {
        code.count == digits.count && code.allSatisfy { $0.isNumber }
    }

    func updateFromPaste(_ pasted: String) {
        let filtered = pasted.filter { $0.isWholeNumber }
        guard !filtered.isEmpty else { return }
        let chars = Array(filtered)
        for i in 0..<digits.count {
            digits[i] = i < chars.count ? String(chars[i]) : ""
        }
    }

    func clear() {
        for i in digits.indices { digits[i] = "" }
    }

    func showUserError(_ message: String) {
        toastIsError = true
        toastMessage = message
        showToast = true
    }

    func showUserSuccess(_ message: String) {
        toastIsError = false
        toastMessage = message
        showToast = true
    }

    // MARK: - Countdown helpers
    func startCountdown() {
        timerCancellable?.cancel()
        guard resendCountdown > 0 else {
            resendCountdown = 0
            return
        }
        timerCancellable = Timer
            .publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.resendCountdown > 0 {
                    self.resendCountdown -= 1
                } else {
                    self.timerCancellable?.cancel()
                }
            }
    }

    func restartCountdown(_ value: Int = 60) {
        resendCountdown = value
        startCountdown()
    }

    deinit {
        timerCancellable?.cancel()
    }
}

