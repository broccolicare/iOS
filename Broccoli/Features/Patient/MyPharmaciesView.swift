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
    
    // Sample data - will be replaced with actual data
    @State private var pharmacies: [PharmacyItem] = [
        PharmacyItem(
            id: "1",
            name: "Aerie Pharmaceuticals Ireland Limited",
            address: "IDA Technology Park, Garrycastle, Athlone, Co. Westmeath, N37 DW40, Ireland"
        ),
        PharmacyItem(
            id: "2",
            name: "Novo Nordisk Production",
            address: "Monksland Industrial Estate, Monksland, Athlone, Co. Roscommon, N37 EA09, Ireland"
        ),
        PharmacyItem(
            id: "3",
            name: "Mallinckrodt Pharmaceuticals Ireland Ltd",
            address: "College Business & Technology Park, D15 TK2V, Blanchardstown Rd N, Cruiserath, Dublin 15"
        ),
        PharmacyItem(
            id: "4",
            name: "Irish Pharmaceutical Healthcare Association Ltd",
            address: "Clanwilliam Terrace, 7 Clanwilliam Terrace, Dublin, D02 CC64, Ireland"
        ),
        PharmacyItem(
            id: "5",
            name: "Lexon Pharmaceuticals Ireland",
            address: "Unit 22 block 4, Port Tunnel Business Park, Clonshaugh industrial estate, Co. Dublin, Ireland"
        ),
        PharmacyItem(
            id: "6",
            name: "Krka Pharma Dublin Ltd.",
            address: "1st Floor, Unit H, Citywest shopping centre, Fortunes Walk, Saggart, Co. Dublin, D24 TYT9"
        )
    ]
    
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
                    VStack(spacing: 12) {
                        ForEach(pharmacies) { pharmacy in
                            PharmacyRow(pharmacy: pharmacy) {
                                // Handle pharmacy tap
                                print("Tapped pharmacy: \(pharmacy.name)")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
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
    }
}

// MARK: - Pharmacy Item Model
struct PharmacyItem: Identifiable {
    let id: String
    let name: String
    let address: String
}

// MARK: - Pharmacy Row Component
struct PharmacyRow: View {
    @Environment(\.appTheme) private var theme
    let pharmacy: PharmacyItem
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
                    
                    Text(pharmacy.address)
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    MyPharmaciesView()
        .environment(\.appTheme, AppTheme.default)
//        .environmentObject(Router())
}
