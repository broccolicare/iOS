//
//  SearchView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/02/26.
//

import SwiftUI

// MARK: - Service Result Row

struct ServiceResultRow: View {
    let service: Service
    let action: () -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.name)
                        .font(theme.typography.semiBold16)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                    
                    if let department = service.department {
                        Text(department.name)
                            .font(theme.typography.medium12)
                            .foregroundStyle(theme.colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                theme.colors.primary.opacity(0.1)
                            )
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.colors.textSecondary)
            }
            .padding(16)
            .background(theme.colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main Search View

struct SearchView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var appGlobalViewModel: AppGlobalViewModel
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    @State private var searchText: String = ""
    @FocusState private var isSearchFieldFocused: Bool
    
    // Computed properties for filtered services
    private var filteredServices: [Service] {
        guard !searchText.isEmpty else { return [] }
        
        let lowercasedSearch = searchText.lowercased()
        return appGlobalViewModel.allServices.filter { service in
            service.name.lowercased().contains(lowercasedSearch) ||
            (service.department?.name.lowercased().contains(lowercasedSearch) ?? false) ||
            (service.description?.lowercased().contains(lowercasedSearch) ?? false)
        }
    }
    
    // Popular services from search history
    private var popularServices: [Service] {
        let recentSearchIds = SearchHistoryManager.getRecentSearches()
        return recentSearchIds.compactMap { serviceId in
            appGlobalViewModel.allServices.first { $0.id == serviceId }
        }
    }
    
    // Determine what to show
    private var shouldShowPopular: Bool {
        searchText.isEmpty && !popularServices.isEmpty
    }
    
    private var shouldShowNoResults: Bool {
        !searchText.isEmpty && filteredServices.isEmpty
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Search")
                        .font(theme.typography.medium28)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible button to balance the layout
                    Image("BackButton")
                        .foregroundStyle(theme.colors.primary)
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                
                // Search input field
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(theme.colors.textSecondary)
                        .font(.system(size: 18))
                    
                    TextField("Search for services", text: $searchText)
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textPrimary)
                        .focused($isSearchFieldFocused)
                    
                    // Clear button
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(theme.colors.textSecondary)
                                .font(.system(size: 18))
                        }
                    }
                }
                .padding(14)
                .background(theme.colors.surface)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.colors.border))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                // Content
                List {
                    // Show Popular Services when no search text and has history
                    if shouldShowPopular {
                        Section {
                            ForEach(popularServices) { service in
                                ServiceResultRow(service: service) {
                                    handleServiceSelection(service)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            Text("Popular Services")
                                .font(theme.typography.semiBold20)
                                .foregroundStyle(theme.colors.textPrimary)
                                .textCase(nil)
                                .padding(.top, 8)
                        }
                    }
                    // Show search results when typing
                    else if !searchText.isEmpty {
                        Section {
                            ForEach(filteredServices) { service in
                                ServiceResultRow(service: service) {
                                    handleServiceSelection(service)
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .padding(.top, 8)
                        
                        // Show no results message
                        if shouldShowNoResults {
                            Section {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundStyle(theme.colors.textSecondary.opacity(0.3))
                                    
                                    Text("No services found")
                                        .font(theme.typography.medium28)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    
                                    Text("Try searching with different keywords")
                                        .font(theme.typography.body)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 60)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                    }
                    // Show empty state when no search and no history
                    else {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.colors.textSecondary.opacity(0.3))
                                
                                Text("Search for services")
                                    .font(theme.typography.medium28)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("Find doctors, specialists, lab tests, and more")
                                    .font(theme.typography.body)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Load services from API
            Task {
                await appGlobalViewModel.loadAllServices()
            }
            
            // Auto-focus the search field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isSearchFieldFocused = true
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleServiceSelection(_ service: Service) {
        // Save to search history
        SearchHistoryManager.saveSearch(serviceId: service.id)
        
        // Set booking context in BookingGlobalViewModel
        bookingViewModel.selectedService = service
        bookingViewModel.selectedDepartmentId = String(service.department?.id ?? 0)
        
        // Navigate based on department
        guard let departmentId = service.department?.id else {
            print("⚠️ Service has no department")
            return
        }
        
        switch departmentId {
        case 1: // General Medicine (GP)
            bookingViewModel.isGP = "1"
            router.push(.gPAppointBookingForm)
        case 2, 3, 4: // Specialist, Nutrition, Laboratory
            router.push(.specialistBookingForm)
        default:
            print("⚠️ Unknown department: \(departmentId)")
        }
    }
}

// MARK: - Supporting Models

struct PopularService: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let color: Color
}

// MARK: - Supporting Views

private struct PopularServiceCard: View {
    @Environment(\.appTheme) private var theme
    let service: PopularService
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(service.color.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: service.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(service.color)
                }
                
                // Service title
                Text(service.title)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textPrimary)
                
                Spacer()
            }
            .padding(16)
            .background(theme.colors.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
}
