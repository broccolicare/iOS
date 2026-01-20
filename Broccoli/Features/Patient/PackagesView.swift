//
//  PackagesView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

// MARK: - Helper to get root view controller
extension UIApplication {
    var keyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
    
    var rootViewController: UIViewController? {
        keyWindow?.rootViewController
    }
}

// MARK: - Package Model
struct PricingPackage: Identifiable {
    let id: Int
    let name: String
    let price: String
    let billingPeriod: String
    let features: [String]
    let backgroundColor: Color
}

struct PackagesView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var packageViewModel: PackageGlobalViewModel
    
    @State private var selectedPackageForPurchase: Package? = nil
    @State private var isShowingPaymentSheet = false
    
    // Package background colors (cycled through)
    private let packageColors: [Color] = [
        Color(red: 0.11, green: 0.47, blue: 0.36),
        Color(red: 0.68, green: 0.78, blue: 0.20),
        Color(red: 0.20, green: 0.35, blue: 0.55),
        Color(red: 0.85, green: 0.33, blue: 0.38)
    ]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("Packages")
                        .font(theme.typography.semiBold20)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        // navigate to notifications screen; if you use router:
                        router.push(.notifications) // example; replace with .notifications route if defined
                    } label: {
                        ZStack {
                            Circle()
                                .fill(theme.colors.primary.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image("notification-icon").frame(width: 40, height: 40)
                            
                            // Notification badge
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pricing Packages")
                                .font(theme.typography.bold24)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            Text("You can compare all the pricing plan available now:")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Loading State
                        if packageViewModel.isLoading {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.top, 40)
                                Text("Loading packages...")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        // Empty State
                        else if packageViewModel.packages.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "doc.plaintext")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
                                    .padding(.top, 40)
                                
                                Text("No packages available")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("Check back later for pricing packages")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 40)
                        }
                        // Packages List
                        else {
                            // Horizontal Scrollable Package Cards
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(Array(packageViewModel.packages.enumerated()), id: \.element.id) { index, package in
                                        PackageCard(
                                            package: package,
                                            backgroundColor: packageColors[index % packageColors.count],
                                            isProcessing: selectedPackageForPurchase?.id == package.id && packageViewModel.isProcessingPayment,
                                            isDisabled: packageViewModel.isProcessingPayment && selectedPackageForPurchase?.id != package.id,
                                            onBuy: { handleBuyPackage(package) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await packageViewModel.loadPackages()
        }
        .onChange(of: packageViewModel.isPaymentReady) { _, isReady in
            if isReady {
                isShowingPaymentSheet = true
            }
        }
        .paymentSheet(
            isPresented: $isShowingPaymentSheet,
            paymentSheet: packageViewModel.paymentSheet ?? PaymentSheet(setupIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        ) { result in
            print("📱 [PackagesView] Payment sheet result: \(result)")
            Task {
                guard let package = selectedPackageForPurchase else {
                    print("❌ [PackagesView] No package selected")
                    return
                }
                
                print("🔄 [PackagesView] Processing payment for package: \(package.name)")
                
                let success = await packageViewModel.onPaymentCompletion(
                    result: result,
                    priceId: package.stripePriceId,
                    name: package.name
                )
                
                if success {
                    print("✅ [PackagesView] Payment successful, resetting state")
                    // Reset state on success
                    selectedPackageForPurchase = nil
                    packageViewModel.resetPaymentState()
                } else {
                    print("❌ [PackagesView] Payment failed")
                }
            }
        }
        .alert("Success", isPresented: $packageViewModel.showSuccessToast) {
            Button("OK", role: .cancel) {
                packageViewModel.showSuccessToast = false
            }
        } message: {
            Text("Package subscription successful!")
        }
        .alert("Error", isPresented: $packageViewModel.showErrorToast) {
            Button("OK", role: .cancel) {
                packageViewModel.showErrorToast = false
                packageViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = packageViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // Handle buy package action
    private func handleBuyPackage(_ package: Package) {
        selectedPackageForPurchase = package
        
        Task {
            // Initialize payment
            guard let paymentResponse = await packageViewModel.initializeSubscriptionPayment(
                priceId: package.stripePriceId,
                name: package.name
            ) else {
                return
            }
            
            // Prepare payment sheet
            packageViewModel.preparePaymentSheet(with: paymentResponse)
        }
    }
}

// MARK: - Package Card Component
struct PackageCard: View {
    @Environment(\.appTheme) private var theme
    let package: Package
    let backgroundColor: Color
    let isProcessing: Bool
    let isDisabled: Bool
    let onBuy: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Package Info
            VStack(alignment: .leading, spacing: 12) {
                Text(package.name)
                    .font(theme.typography.semiBold22)
                    .foregroundStyle(.white)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatPrice(package.price))
                        .font(theme.typography.bold32)
                        .foregroundStyle(.white)
                    
                    Text("/ \(package.billingPeriod)")
                        .font(theme.typography.regular14)
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(package.features) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.name)
                                    .font(theme.typography.semiBold14)
                                    .foregroundStyle(.white)
                                
                                if let description = feature.description {
                                    Text(description)
                                        .font(theme.typography.regular12)
                                        .foregroundStyle(.white.opacity(0.8))
                                        .lineLimit(3)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .frame(width: 280, alignment: .leading)
            
            Spacer(minLength: 20)
            
            // Buy Now Button
            Button(action: onBuy) {
                if isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                        Text("Processing...")
                            .font(theme.typography.semiBold16)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                } else {
                    Text("Buy Now")
                        .font(theme.typography.semiBold16)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }
            .background(isDisabled ? Color.black.opacity(0.1) : Color.black.opacity(0.3))
            .cornerRadius(12)
            .disabled(isProcessing || isDisabled)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .frame(minHeight: 480)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    // Helper function to format price (defaults to EUR)
    private func formatPrice(_ price: String) -> String {
        return "€\(price)"
    }
}

// MARK: - Preview
#Preview {
    PackagesView()
        .environment(\.appTheme, AppTheme.default)
}

