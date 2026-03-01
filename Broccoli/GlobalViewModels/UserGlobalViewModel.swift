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
    private let _userService: UserServiceProtocol
    public var userService: UserServiceProtocol { _userService }
    private let secureStore: SecureStore
    
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    @Published public var profileData: UserProfileData? = nil
    
    public init(userService: UserServiceProtocol, secureStore: SecureStore = SecureStore()) {
        self._userService = userService
        self.secureStore = secureStore
        
        // Load cached user data immediately from secure store
        loadCachedUserProfile()
    }
    
    // MARK: - Computed Properties
    
    public var formattedSpecializations: String {
        guard let specialization = profileData?.specialization else {
            return "Not specified"
        }
        return specialization.name
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
              let postalCode = profileData?.profile?.postalCode,
              let country = profileData?.profile?.country else {
            return ""
        }
        return "\(address), \(country) - \(postalCode)"
    }
    
    // MARK: - Methods
    
    /// Load cached user profile from secure store (synchronous, fast)
    private func loadCachedUserProfile() {
        do {
            if let userDataString: String = try secureStore.retrieve(for: SecureStore.Keys.userProfileData),
               let userData = userDataString.data(using: .utf8) {
                let profile = try JSONDecoder().decode(UserProfileData.self, from: userData)
                profileData = profile
                print("✅ Loaded cached user profile: \(profile.name)")
            }
        } catch {
            print("⚠️ No cached profile data or failed to decode: \(error)")
        }
    }
    
    /// Save user profile to secure store for offline access
    private func cacheUserProfile(_ profile: UserProfileData) {
        do {
            let userData = try JSONEncoder().encode(profile)
            let userDataString = String(data: userData, encoding: .utf8) ?? ""
            try secureStore.store(userDataString, for: SecureStore.Keys.userProfileData)
            print("✅ Cached user profile data")
        } catch {
            print("❌ Failed to cache profile data: \(error)")
        }
    }
    
    public func fetchProfileDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            let response = try await userService.fetchUserProfile()
            profileData = response.data
            
            // Cache the profile data for offline access
            cacheUserProfile(response.data)
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
            
            // Cache the updated profile data
            cacheUserProfile(response.data)
            
            showSuccessToast = true
            print("✅ Profile updated successfully")
        } catch {
            print("❌ Profile update failed: \(error)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
        }
        
        isLoading = false
    }
    
    /// Uploads a new avatar image. On success, patches `profileData.profile.profileImage`
    /// locally so the UI reflects the change without a full profile re-fetch.
    @discardableResult
    public func uploadAvatar(imageData: Data) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await userService.uploadAvatar(imageData: imageData)
            guard response.success, let newURL = response.data?.profileImage else {
                errorMessage = response.message
                showErrorToast = true
                return false
            }
            // Refresh full profile so all fields (including profile_image) stay in sync
            await fetchProfileDetail()
            showSuccessToast = true
            print("✅ Avatar uploaded: \(newURL)")
            return true
        } catch {
            print("❌ Avatar upload failed: \(error)")
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showErrorToast = true
            return false
        }
    }

}
