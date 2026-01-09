//
//  PackageGlobalViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation
import Combine
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

@MainActor
public final class PackageGlobalViewModel: ObservableObject {
    private let packageService: PackageServiceProtocol
    
    // Published UI state
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    
    // Package data
    @Published public var packages: [Package] = []
    @Published public var selectedPackage: Package? = nil
    
    // Payment state
    @Published public var paymentSheet: PaymentSheet? = nil
    @Published public var paymentResult: PaymentSheetResult? = nil
    @Published public var isPaymentReady: Bool = false
    @Published public var currentPaymentIntentId: String? = nil
    @Published public var currentClientSecret: String? = nil
    
    // Eligibility state
    @Published public var isEligible: Bool = false
    @Published public var eligibilityMessage: String? = nil
    
    public init(packageService: PackageServiceProtocol) {
        self.packageService = packageService
    }
    
    // MARK: - Computed Properties
    
    public var hasPackages: Bool {
        return !packages.isEmpty
    }
    
    // MARK: - Methods
    
    /// Load available packages
    public func loadPackages() async {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        
        do {
            let response = try await packageService.getPackages()
            
            if response.success {
                packages = response.packages
            } else {
                errorMessage = response.message ?? "Failed to load packages"
                showErrorToast = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            packages = []
        }
        
        isLoading = false
    }
    
    /// Check service eligibility for a package
    public func checkServiceEligibility(serviceId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        
        do {
            let response = try await packageService.getServiceEligibility(serviceId: serviceId)
            
            if response.success {
                isEligible = response.eligible
                eligibilityMessage = response.message
                isLoading = false
                return response.eligible
            } else {
                errorMessage = response.message ?? "Failed to check eligibility"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Initialize subscription payment
    public func initializeSubscriptionPayment(priceId: String, name: String) async -> PaymentInitializeResponse? {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        
        do {
            let response = try await packageService.initializeSubscriptionPayment(priceId: priceId, name: name)
            
            if response.success == true {
                isLoading = false
                return response
            } else {
                errorMessage = response.message ?? "Failed to initialize payment"
                showErrorToast = true
                isLoading = false
                return nil
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return nil
        }
    }
    
    /// Prepare payment sheet with payment intent
    public func preparePaymentSheet(with paymentResponse: PaymentInitializeResponse) {
        guard let clientSecret = paymentResponse.clientSecret else {
            errorMessage = "No client secret received"
            showErrorToast = true
            return
        }
        
        guard let publishableKey = paymentResponse.publishableKey else {
            errorMessage = "No publishable key received"
            showErrorToast = true
            return
        }
        
        // Store payment intent ID and client secret
        currentPaymentIntentId = paymentResponse.paymentIntent?.id
        currentClientSecret = clientSecret
        
        // Configure Stripe
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Broccoli Care"
        config.allowsDelayedPaymentMethods = true
        
        // Initialize payment sheet
        paymentSheet = PaymentSheet(
            paymentIntentClientSecret: clientSecret,
            configuration: config
        )
        
        isPaymentReady = true
    }
    
    /// Confirm subscription payment after successful payment
    public func confirmSubscriptionPayment(
        priceId: String,
        paymentMethodId: String,
        name: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        showSuccessToast = false
        
        do {
            let response = try await packageService.confirmSubscriptionPayment(
                priceId: priceId,
                paymentMethodId: paymentMethodId,
                name: name
            )
            
            if response.success {
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to confirm payment"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Handle payment sheet completion
    public func onPaymentCompletion(
        result: PaymentSheetResult,
        priceId: String,
        paymentMethodId: String,
        name: String
    ) async -> Bool {
        paymentResult = result
        
        switch result {
        case .completed:
            // Payment successful, confirm on backend
            return await confirmSubscriptionPayment(
                priceId: priceId,
                paymentMethodId: paymentMethodId,
                name: name
            )
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorToast = true
            return false
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            return false
        }
    }
    
    /// Reset payment state
    public func resetPaymentState() {
        paymentSheet = nil
        isPaymentReady = false
        currentPaymentIntentId = nil
        currentClientSecret = nil
        paymentResult = nil
    }
}
