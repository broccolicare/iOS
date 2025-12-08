//
//  SpecialityListView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/11/25.
//

import SwiftUI

struct SpecialityListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @State private var selectedSpeciality: SpecialityItem?
    
    // Sample data - will be replaced with actual data
    let specialities: [SpecialityItem] = [
        SpecialityItem(id: "1", name: "Oncologist", price: "€230/-"),
        SpecialityItem(id: "2", name: "Ophthalmologist", price: "€230/-"),
        SpecialityItem(id: "3", name: "Orthopedist", price: "€230/-"),
        SpecialityItem(id: "4", name: "Gynaecologist", price: "€230/-"),
        SpecialityItem(id: "5", name: "ENT", price: "€230/-"),
        SpecialityItem(id: "6", name: "Neurologist", price: "€230/-"),
        SpecialityItem(id: "7", name: "Cardiologist", price: "€230/-")
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
                    
                    Text("Book Specialist")
                        .font(theme.typography.medium24)
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
                
                // Speciality List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(specialities) { speciality in
                            SpecialityRow(
                                speciality: speciality,
                                isSelected: selectedSpeciality?.id == speciality.id
                            ) {
                                selectedSpeciality = speciality
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                
                Spacer()
            }
            
            // Next Button (Fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    if let selected = selectedSpeciality {
                        router.push(.specilistBookingForm)
                    }
                }) {
                    Text("Next")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedSpeciality != nil ? theme.colors.primary : theme.colors.primary.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(selectedSpeciality == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Speciality Item Model
struct SpecialityItem: Identifiable {
    let id: String
    let name: String
    let price: String
}

// MARK: - Speciality Row Component
struct SpecialityRow: View {
    @Environment(\.appTheme) private var theme
    let speciality: SpecialityItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(speciality.name)
                    .font(theme.typography.regular16)
                    .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                
                Spacer()
                
                Text(speciality.price)
                    .font(theme.typography.medium16)
                    .foregroundStyle(isSelected ? .white : theme.colors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? theme.colors.textPrimary : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    SpecialityListView()
    .environment(\.appTheme, AppTheme.default)
}
