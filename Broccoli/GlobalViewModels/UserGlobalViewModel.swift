//
//  UserGlobalViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 06/11/25.
//
import Foundation
import Combine

@MainActor
public final class UserGlobalViewModel: ObservableObject {
    private let userService: UserServiceProtocol
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    @Published public var profileData: UserProfileData? = nil
    
    public init(userService: UserServiceProtocol) {
        self.userService = userService
    }
    
    // MARK: - Computed Properties
    
    public var formattedSpecializations: String {
        guard let specializations = profileData?.specializations, !specializations.isEmpty else {
            return "Not specified"
        }
        return specializations.map { $0 }.joined(separator: ", ")
    }
    
    public var formattedPhoneNumber: String {
        guard let phoneCode = profileData?.profile?.phoneCode,
              let phone = profileData?.profile?.phone else {
            return ""
        }
        return "\(phoneCode) \(phone)"
    }
    
    public var formattedAddress: String {
        guard let address = profileData?.profile?.address,
              let city = profileData?.profile?.city,
              let country = profileData?.profile?.country else {
            return ""
        }
        return "\(address), \(city), \(country)"
    }
    
    // MARK: - Methods
    
    public func fetchProfileDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await userService.fetchUserProfile()
            profileData = response.data
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        isLoading = false
    }
    
    public func updateProfile(data: [String: Any]) async {
        print("🚀 Starting profile update...")
        isLoading = true
        errorMessage = nil
        do {
            let response = try await userService.updateProfile(data: data)
            profileData = response.data
            showSuccessToast = true
            print("✅ Profile updated successfully")
        } catch {
            print("❌ Profile update failed: \(error)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        
        isLoading = false
    }
    
}
