//
//  PackagesView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/12/25.
//

import SwiftUI

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
                                            backgroundColor: packageColors[index % packageColors.count]
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
    }
}

// MARK: - Package Card Component
struct PackageCard: View {
    @Environment(\.appTheme) private var theme
    let package: Package
    let backgroundColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Package Info
            VStack(alignment: .leading, spacing: 12) {
                Text(package.name)
                    .font(theme.typography.semiBold22)
                    .foregroundStyle(.white)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(formatPrice(package.price, currency: package.currency))
                        .font(theme.typography.bold32)
                        .foregroundStyle(.white)
                    
                    if let billingPeriod = package.billingPeriod {
                        Text("/ \(billingPeriod)")
                            .font(theme.typography.regular14)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(package.features, id: \.self) { feature in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(.white)
                            
                            Text(feature)
                                .font(theme.typography.regular14)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(20)
            .frame(width: 280, alignment: .leading)
            
            Spacer(minLength: 20)
            
            // Buy Now Button
            Button(action: {
                // Handle buy action
                print("Buy package: \(package.name)")
            }) {
                Text("Buy Now")
                    .font(theme.typography.semiBold16)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 280)
        .frame(minHeight: 480)
        .background(backgroundColor)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // Helper function to format price
    private func formatPrice(_ price: String, currency: String?) -> String {
        let currencySymbol: String
        switch currency {
        case "EUR": currencySymbol = "€"
        case "GBP": currencySymbol = "£"
        case "USD": currencySymbol = "$"
        default: currencySymbol = currency ?? "€"
        }
        return "\(currencySymbol)\(price)"
    }
}

// MARK: - Preview
#Preview {
    PackagesView()
        .environment(\.appTheme, AppTheme.default)
}

