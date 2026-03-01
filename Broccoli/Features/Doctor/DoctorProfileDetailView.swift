//
//  DoctorProfileDetailView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 20/11/25.
//

import SwiftUI

struct DoctorProfileDetailView: View {
    
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
        @EnvironmentObject private var userVM: UserGlobalViewModel
        @EnvironmentObject private var router: Router
    
    var body: some View {
        ZStack(alignment: .top) {
            // Green gradient background - extends to top edge
            LinearGradient(
                gradient: Gradient(colors: [
                    theme.colors.gradientStart,
                    theme.colors.gradientEnd
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 0) {
                // Header with gradient background
                ZStack(alignment: .top) {
                    VStack(spacing: 0) {
                        // Navigation buttons
                        HStack {
                            Button(action: {
                                router.pop()
                            }) {
                                Image("back-icon-white")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(theme.colors.primary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                router.push(.editDoctorProfile)
                            }) {
                                Image("edit-profile-icon")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(theme.colors.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    .frame(height: 100)
                    
                    // Profile Image and Info (overlapping the gradient)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 120, height: 120)
                            .overlay(
                                Group {
                                    if let urlString = userVM.profileData?.profile?.profileImage,
                                       let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .success(let image):
                                                image.resizable()
                                                    .scaledToFill()
                                                    .frame(width: 120, height: 120)
                                                    .clipShape(Circle())
                                            default:
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundStyle(.gray)
                                            }
                                        }
                                    } else {
                                        Circle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: 110, height: 110)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 50))
                                                    .foregroundStyle(.gray)
                                            )
                                    }
                                }
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                        
                        // Name
                        Text(userVM.profileData?.name ?? "")
                            .font(theme.typography.bold30)
                            .foregroundStyle(theme.colors.textPrimary)

                        
                        // Specialization Badge - Using computed property from userVM
                        Text(userVM.formattedSpecializations)
                            .font(theme.typography.bold16)
                            .foregroundStyle(theme.colors.profileDetailTextColor)
                            .multilineTextAlignment(.center)
                        
                        // License Number
                        Text(userVM.profileData?.licenseNumber ?? "N/A")
                            .font(theme.typography.bold16)
                            .foregroundStyle(theme.colors.profileDetailTextColor)
                    }
                    .padding(.top, 40)
                }
                
                // Content Sections
                ScrollView {
                    VStack(spacing: 20) {
                        // Personal Information Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Personal Information")
                                .font(theme.typography.bold18)
                                .foregroundStyle(theme.colors.textPrimary)
                                .padding(.horizontal, 20)
                            
                            VStack(spacing: 0) {
                                DoctorInfoRow(
                                    label: "Gender",
                                    value: userVM.profileData?.profile?.gender?.capitalized ?? "Male",
                                    showDivider: false
                                )
                                
                                DoctorInfoRow(
                                    label: "Date of Birth",
                                    value:  userVM.profileData?.profile?.dateOfBirth ?? "December 19, 1980",
                                    showDivider: false
                                )
                                
                                DoctorInfoRow(
                                    label: "Address",
                                    value: userVM.formattedAddress,
                                    showDivider: false
                                )
                                
                                DoctorInfoRow(
                                    label: "Phone Number",
                                    value: userVM.formattedPhoneNumber,
                                    showDivider: false
                                )
                                
                                DoctorInfoRow(
                                    label: "Email",
                                    value:  userVM.profileData?.email ?? "",
                                    showDivider: false
                                )
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Available Time Slots Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Available Time Slots")
                                .font(theme.typography.bold18)
                                .foregroundStyle(theme.colors.textPrimary)
                        
                            TimeSlotRow(time: """
                                9:00 AM - 10:00 AM
                                12:00 PM - 02:00 PM
                                4:00 PM - 6:00 PM
                                """)
                        }.padding(.horizontal, 20)
                        
                        // Pricing Section
                        // VStack(alignment: .leading, spacing: 16) {
                        //     Text("Pricing")
                        //         .font(theme.typography.bold18)
                        //         .foregroundStyle(theme.colors.textPrimary)
                                
                            
                        //     HStack(spacing: 16) {
                        //         // Clock Icon
                        //         Rectangle()
                        //             .fill(theme.colors.background)
                        //             .frame(width: 48, height: 48)
                        //             .cornerRadius(8)
                        //             .overlay(
                        //                 Image(systemName: "clock")
                        //                     .font(.system(size: 20))
                        //                     .foregroundStyle(theme.colors.textPrimary)
                        //             )
                                
                        //         VStack(alignment: .leading, spacing: 4) {
                        //             Text("€49")
                        //                 .font(theme.typography.semiBold20)
                        //                 .foregroundStyle(theme.colors.textPrimary)
                                    
                        //             Text("30 minutes")
                        //                 .font(theme.typography.regular14)
                        //                 .foregroundStyle(theme.colors.profileDetailTextColor)
                        //         }
                                
                        //         Spacer()
                        //     }
                        // }.padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await userVM.fetchProfileDetail()
        }
    }
}



// MARK: - Preview

#Preview {
    NavigationView {
        DoctorProfileDetailView()
            .environmentObject(UserGlobalViewModel(userService: UserService(httpClient: HTTPClient())))
            .environment(\.appTheme, AppTheme.default)
    }
}
