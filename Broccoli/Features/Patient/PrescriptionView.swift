//
//  PrescriptionView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal
//

import SwiftUI

struct PrescriptionView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var userVM: UserGlobalViewModel
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    // Get active treatments from API
    private var activeTreatments: [Treatment] {
        bookingViewModel.treatments.filter { $0.isActive }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("Prescription")
                        .font(theme.typography.medium24)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        // navigate to notifications screen; if you use router:
                        router.push(.notifications)
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
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Select Prescription")
                            .font(theme.typography.bold30)
                            .foregroundStyle(theme.colors.textPrimary)
                        
                        // Description
                        Text("Get expert advice from Irish-registered dietitian's - no referral needed. Book now for fast, credible, anti-holistic care tailored to you.")
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textPrimary)
                            .lineSpacing(4)
                        
                        // Loading state
                        if bookingViewModel.isLoading {
                            VStack {
                                ProgressView()
                                    .padding(.top, 50)
                                Text("Loading treatments...")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        // Empty state
                        else if activeTreatments.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "pills.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.colors.textSecondary)
                                Text("No treatments available")
                                    .font(theme.typography.regular16)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        }
                        // Treatments list
                        else {
                            FlowLayout(spacing: 12) {
                                ForEach(activeTreatments) { treatment in
                                    TreatmentChip(
                                        treatment: treatment,
                                        isSelected: bookingViewModel.selectedPrescription?.id == String(treatment.id)
                                    ) {
                                        // Convert Treatment to PrescriptionItem for storage
                                        let prescriptionItem = PrescriptionItem(
                                            id: String(treatment.id),
                                            name: treatment.name,
                                            gender: .both
                                        )
                                        bookingViewModel.selectedPrescription = prescriptionItem
                                        // Navigate to book prescription screen
                                        router.push(.bookPrescription)
                                    }
                                }
                            }
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Reset prescription flow when returning to prescription list
            bookingViewModel.resetPrescriptionFlow()
        }
        .task {
            // Fetch treatments when view appears
            if bookingViewModel.treatments.isEmpty {
                await bookingViewModel.fetchActiveTreatments()
            }
        }
    }
}

// MARK: - Prescription Item Model
public struct PrescriptionItem: Identifiable, Codable {
    public let id: String
    public let name: String
    public let gender: Gender
    
    public enum Gender: String, Codable {
        case male
        case female
        case both
    }
    
    public init(id: String, name: String, gender: Gender) {
        self.id = id
        self.name = name
        self.gender = gender
    }
}

// MARK: - Treatment Chip Component
struct TreatmentChip: View {
    @Environment(\.appTheme) private var theme
    let treatment: Treatment
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(treatment.name)
                .font(theme.typography.regular14)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(isSelected ? theme.colors.primary : Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.colors.primary : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                )
        }
    }
}

// MARK: - Flow Layout for wrapping chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    PrescriptionView()
        .environmentObject(Router.shared)
        .environmentObject(UserGlobalViewModel(userService: UserService(httpClient: HTTPClient())))
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environment(\.appTheme, AppTheme.default)
}
