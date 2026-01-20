//
//  PackageGlobalViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import Foundation
import Combine
import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet
@_spi(STP) import StripeCore

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
    @Published public var isProcessingPayment: Bool = false
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
            packages = response.data
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
        isProcessingPayment = true
        errorMessage = nil
        showErrorToast = false
        
        do {
            let response = try await packageService.initializeSubscriptionPayment(priceId: priceId, name: name)
            
            print("🔍 [PackageViewModel] Initialize Subscription Payment Response:")
            print("   - setupIntent: \(response.setupIntent != nil ? "exists" : "nil")")
            print("   - setupIntent.id: \(response.setupIntent?.id ?? "nil")")
            print("   - setupIntent.clientSecret: \(response.setupIntent?.clientSecret.prefix(20) ?? "nil")...")
            print("   - customer.id: \(response.customer?.id ?? "nil")")
            print("   - customerId (computed): \(response.customerId ?? "nil")")
            print("   - ephemeralKey: \(response.ephemeralKey != nil ? "exists" : "nil")")
            print("   - ephemeralKeySecret (computed): \(response.ephemeralKeySecret ?? "nil")")
            print("   - publishableKey: \(response.publishableKey?.prefix(20) ?? "nil")...")
            
            // IMPORTANT: For setupIntent with saved payment methods, the backend MUST create
            // the setupIntent with the customer parameter. This is a Stripe requirement.
            // Unlike paymentIntent, setupIntent requires customer to be set during creation.
            
            // Check if we have the required data for payment
            if response.publishableKey != nil && response.clientSecret != nil {
                isProcessingPayment = false
                return response
            } else {
                errorMessage = "Missing required payment data"
                showErrorToast = true
                isProcessingPayment = false
                return nil
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isProcessingPayment = false
            return nil
        }
    }
    
    /// Prepare payment sheet with payment intent or setup intent
    public func preparePaymentSheet(with paymentResponse: PaymentInitializeResponse) {
        guard let clientSecret = paymentResponse.clientSecret else {
            errorMessage = "No client secret received"
            showErrorToast = true
            print("❌ [PackageViewModel] No client secret in response")
            return
        }
        
        guard let publishableKey = paymentResponse.publishableKey else {
            errorMessage = "No publishable key received"
            showErrorToast = true
            print("❌ [PackageViewModel] No publishable key in response")
            return
        }
        
        print("✅ [PackageViewModel] Preparing payment sheet")
        print("   - Has setupIntent: \(paymentResponse.setupIntent != nil)")
        print("   - setupIntent.id: \(paymentResponse.setupIntent?.id ?? "nil")")
        print("   - Has paymentIntent: \(paymentResponse.paymentIntent != nil)")
        print("   - paymentIntent.id: \(paymentResponse.paymentIntent?.id ?? "nil")")
        print("   - Has customer: \(paymentResponse.customerId != nil)")
        print("   - Client secret: \(clientSecret.prefix(20))...")
        print("   - Publishable key: \(publishableKey.prefix(20))...")
        
        // CRITICAL: Set the publishable key on Stripe SDK
        STPAPIClient.shared.publishableKey = publishableKey
        print("   - Configured STPAPIClient with publishable key")
        
        // Store payment intent/setup intent ID and client secret
        // If ID is not provided, extract it from the client secret
        var intentId = paymentResponse.setupIntent?.id ?? paymentResponse.paymentIntent?.id
        if intentId == nil {
            // Extract setupIntent ID from client secret (format: seti_xxxxx_secret_yyyy)
            if clientSecret.hasPrefix("seti_") {
                intentId = String(clientSecret.split(separator: "_secret_")[0])
            } else if clientSecret.hasPrefix("pi_") {
                intentId = String(clientSecret.split(separator: "_secret_")[0])
            }
        }
        
        currentPaymentIntentId = intentId
        currentClientSecret = clientSecret
        
        print("   - Stored intentId: \(currentPaymentIntentId ?? "nil")")
        
        // Configure payment sheet - match booking flow configuration
        var config = PaymentSheet.Configuration()
        config.merchantDisplayName = "Broccoli Care"
        config.allowsDelayedPaymentMethods = true
        config.returnURL = "broccoli://stripe-redirect"
        
        // Configure customer info if available
        if let customerId = paymentResponse.customerId,
           let ephemeralKeySecret = paymentResponse.ephemeralKeySecret {
            print("   - Configuring customer: \(customerId)")
            config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
        } else {
            print("   - No customer configuration")
        }
        
        // Initialize payment sheet based on whether it's a setupIntent (subscription) or paymentIntent (one-time)
        if paymentResponse.setupIntent != nil {
            print("   - Creating PaymentSheet with setupIntentClientSecret")
            // For subscriptions, use setupIntentClientSecret
            paymentSheet = PaymentSheet(
                setupIntentClientSecret: clientSecret,
                configuration: config
            )
        } else {
            print("   - Creating PaymentSheet with paymentIntentClientSecret")
            // For one-time payments, use paymentIntentClientSecret
            paymentSheet = PaymentSheet(
                paymentIntentClientSecret: clientSecret,
                configuration: config
            )
        }
        
        print("✅ [PackageViewModel] Payment sheet created successfully")
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
            
            if response.success == true || response.subscription != nil {
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
        name: String
    ) async -> Bool {
        paymentResult = result
        
        switch result {
        case .completed:
            print("✅ [PackageViewModel] Payment completed, retrieving payment method")
            
            // For setupIntent, we need to retrieve the payment method from Stripe
            guard let setupIntentId = currentPaymentIntentId else {
                errorMessage = "Setup intent ID not found"
                showErrorToast = true
                print("❌ [PackageViewModel] No setupIntent ID available")
                return false
            }
            
            // Retrieve the setupIntent to get the payment method
            do {
                let setupIntent = try await STPAPIClient.shared.retrieveSetupIntent(withClientSecret: currentClientSecret ?? "")
                
                guard let paymentMethodId = setupIntent.paymentMethodID else {
                    errorMessage = "Payment method not found in setup intent"
                    showErrorToast = true
                    print("❌ [PackageViewModel] No payment method in setupIntent")
                    return false
                }
                
                print("✅ [PackageViewModel] Retrieved payment method: \(paymentMethodId)")
                
                // Confirm subscription with backend
                return await confirmSubscriptionPayment(
                    priceId: priceId,
                    paymentMethodId: paymentMethodId,
                    name: name
                )
            } catch {
                errorMessage = "Failed to retrieve payment method: \(error.localizedDescription)"
                showErrorToast = true
                print("❌ [PackageViewModel] Error retrieving setupIntent: \(error)")
                return false
            }
            
        case .failed(let error):
            errorMessage = "Payment failed: \(error.localizedDescription)"
            showErrorToast = true
            print("❌ [PackageViewModel] Payment failed: \(error)")
            return false
            
        case .canceled:
            errorMessage = "Payment was canceled"
            showErrorToast = true
            print("⚠️ [PackageViewModel] Payment canceled by user")
            return false
        }
    }
    
    /// Reset payment state
    public func resetPaymentState() {
        paymentSheet = nil
        isPaymentReady = false
        isProcessingPayment = false
        currentPaymentIntentId = nil
        currentClientSecret = nil
        paymentResult = nil
    }
}
