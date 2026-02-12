//
//  BookPrescriptionView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/12/25.
//

import SwiftUI

struct BookPrescriptionView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
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
                    
                    Text("Book Prescription")
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
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // Treatment Name
                        if let treatment = getSelectedTreatment() {
                            Text(treatment.name)
                                .font(theme.typography.bold30)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            // Prescription Information
                            VStack(alignment: .leading, spacing: 12) {
                                Text("The information that you provide is covered by the same patient-doctor confidentiality as in a normal face to face consultation.")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("If medically suitable, your prescription will be sent directly to your chosen pharmacy by secure email (Healthmail).")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("We refund the full amount if our Doctors cannot treat you.")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                Text("Please consider your responses and answer honestly and clearly. The questions will be based on:")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textPrimary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    BulletPoint(text: "The treatment you are requesting")
                                    BulletPoint(text: "Your health")
                                    BulletPoint(text: "Your medical history")
                                }
                                .padding(.leading, 8)
                            }
                            
                            // Description/Details Section
                            if let details = treatment.details, !details.isEmpty {
                                // Show HTML details
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Treatment Information")
                                        .font(theme.typography.semiBold18)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .padding(.top, 8)
                                    
                                    HTMLTextView(
                                        htmlString: details,
                                        font: UIFont.systemFont(ofSize: 14),
                                        textColor: UIColor(theme.colors.textPrimary)
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else if let description = treatment.description, !description.isEmpty {
                                // Fallback to plain text description
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("What is \(extractTreatmentType(from: treatment.name))?")
                                        .font(theme.typography.semiBold18)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .padding(.top, 8)
                                    
                                    Text(description)
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .lineSpacing(4)
                                }
                            }
                        } else {
                            // Fallback if no treatment is selected
                            VStack(spacing: 16) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 48))
                                    .foregroundStyle(theme.colors.textSecondary)
                                Text("No treatment selected")
                                    .font(theme.typography.regular16)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        }
                        
                        // Bottom spacing
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            
            // Fixed Bottom Button
            if getSelectedTreatment() != nil {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        // Navigate to questionnaire screen
                        router.push(.prescriptionQuestions)
                    }) {
                        Text("Ok, Let's Start")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.colors.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(
                        Color.white
                            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: -5)
                    )
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Helper Functions
    
    private func getSelectedTreatment() -> Treatment? {
        guard let selectedPrescription = bookingViewModel.selectedPrescription,
              let treatmentId = Int(selectedPrescription.id) else {
            return nil
        }
        return bookingViewModel.treatments.first { $0.id == treatmentId }
    }
    
    private func extractTreatmentType(from name: String) -> String {
        // Remove "Treatment" suffix if present
        let cleanedName = name.replacingOccurrences(of: " Treatment", with: "")
        return cleanedName
    }
}

// MARK: - Bullet Point Component
struct BulletPoint: View {
    @Environment(\.appTheme) private var theme
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textPrimary)
            
            Text(text)
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textPrimary)
        }
    }
}

// MARK: - Preview
#Preview {
    BookPrescriptionView()
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environment(\.appTheme, AppTheme.default)
}
