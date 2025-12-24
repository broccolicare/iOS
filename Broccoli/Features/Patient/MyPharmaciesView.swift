//
//  MyPharmaciesView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 29/11/25.
//

import SwiftUI

struct MyPharmaciesView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var pharmacyViewModel: PharmacyGlobalViewModel
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("My Pharmacies")
                        .font(theme.typography.medium22)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Circle()
                        .fill(.clear)
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Pharmacies List
                ScrollView(showsIndicators: false) {
                    if pharmacyViewModel.isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.top, 40)
                            Text("Loading pharmacies...")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                    } else if pharmacyViewModel.pharmacies.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "cross.case")
                                .font(.system(size: 48))
                                .foregroundStyle(theme.colors.textSecondary.opacity(0.5))
                                .padding(.top, 40)
                            
                            Text("No pharmacies found")
                                .font(theme.typography.semiBold18)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            Text("Add your first pharmacy to get started")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 40)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(pharmacyViewModel.pharmacies) { pharmacy in
                                PharmacyRow(pharmacy: pharmacy) {
                                    // Navigate to edit pharmacy screen
                                    pharmacyViewModel.selectedPharmacy = pharmacy
                                    router.push(.editPharmacy(pharmacy: pharmacy))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                Spacer()
            }
            
            // Add New Pharmacy Button (Fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    // Handle add new pharmacy
                    print("Add New Pharmacy tapped")
                    router.push(.addPharmacy)
                }) {
                    Text("Add New Pharmacy")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.colors.primary)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            await pharmacyViewModel.loadPharmacies()
        }
    }
}

// MARK: - Pharmacy Row Component
struct PharmacyRow: View {
    @Environment(\.appTheme) private var theme
    let pharmacy: Pharmacy
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top,spacing: 16) {
                // Icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.93, green: 0.96, blue: 0.98))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(theme.colors.primary)
                }
                
                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    Text(pharmacy.name)
                        .font(theme.typography.semiBold18)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let address = pharmacy.address {
                        Text(formatAddress(pharmacy))
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textSecondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
            }
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatAddress(_ pharmacy: Pharmacy) -> String {
        var addressParts: [String] = []
        
        if let address = pharmacy.address {
            addressParts.append(address)
        }
        if let city = pharmacy.city {
            addressParts.append(city)
        }
        if let state = pharmacy.state {
            addressParts.append(state)
        }
        if let postalCode = pharmacy.postalCode {
            addressParts.append(postalCode)
        }
        if let country = pharmacy.country {
            addressParts.append(country)
        }
        
        return addressParts.joined(separator: ", ")
    }
}

// MARK: - Preview
#Preview {
    MyPharmaciesView()
        .environment(\.appTheme, AppTheme.default)
//        .environmentObject(Router())
}
