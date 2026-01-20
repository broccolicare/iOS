//
//  SpecialtyListView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 27/11/25.
//

import SwiftUI

struct SpecialtyListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var appViewModel: AppGlobalViewModel
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    let departmentId: String?
    
    @State private var selectedService: Service?
    
    // Computed property for dynamic title
    private var screenTitle: String {
        guard let deptId = departmentId else { return "Book Service" }
        
        switch deptId {
        case "2":
            return "Book Specialist"
        case "3":
            return "Book Nutritionist"
        case "4":
            return "Book Blood Test"
        default:
            return "Book Service"
        }
    }
    
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
                    
                    Text(screenTitle)
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
                
                // Specialty List
                ScrollView(showsIndicators: false) {
                    if bookingViewModel.isLoading {
                        VStack {
                            ProgressView()
                                .padding(.top, 50)
                            Text("Loading services...")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                                .padding(.top, 8)
                        }
                    } else if bookingViewModel.services.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "stethoscope")
                                .font(.system(size: 48))
                                .foregroundStyle(theme.colors.textSecondary)
                            Text("No services available")
                                .font(theme.typography.regular16)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 50)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(bookingViewModel.services) { service in
                                ServiceRow(
                                    service: service,
                                    isSelected: selectedService?.id == service.id
                                ) {
                                    selectedService = service
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                }
                
                Spacer()
            }
            
            // Next Button (Fixed at bottom)
            VStack {
                Spacer()
                
                Button(action: {
                    if let selected = selectedService {
                        // Save selected service to BookingGlobalViewModel
                        bookingViewModel.selectedService = selected
                        bookingViewModel.selectedDepartmentId = departmentId
                        router.push(.specialistBookingForm)
                    }
                }) {
                    Text("Next")
                        .font(theme.typography.button)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(selectedService != nil ? theme.colors.primary : theme.colors.primary.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(selectedService == nil)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(
                    Color.white
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                )
            }
        }
        .navigationBarHidden(true)
        .task {
            // Reset booking form to clear previous selections
            bookingViewModel.resetBookingForm()
            
            // Load services when view appears
            if let deptId = departmentId {
                await bookingViewModel.loadDepartmentServices(departmentId: deptId)
            }
        }
    }
}

// MARK: - Service Row Component
struct ServiceRow: View {
    @Environment(\.appTheme) private var theme
    let service: Service
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(theme.typography.regular16)
                        .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                    
                    if let description = service.description {
                        Text(description)
                            .font(theme.typography.regular12)
                            .foregroundStyle(isSelected ? .white.opacity(0.8) : theme.colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Text("€\(service.price)")
                    .font(theme.typography.bold16)
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
    SpecialtyListView(departmentId: nil)
        .environmentObject(Router.shared)
        .environmentObject(AppGlobalViewModel(appService: AppService(httpClient: HTTPClient())))
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environment(\.appTheme, AppTheme.default)
}
