//
//  PharmacyGlobalViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 23/12/25.
//

import Foundation
import Combine

@MainActor
public final class PharmacyGlobalViewModel: ObservableObject {
    private let pharmacyService: PharmacyServiceProtocol
    
    // Published UI state
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var showErrorToast: Bool = false
    @Published public var showSuccessToast: Bool = false
    
    // Pharmacy data
    @Published public var pharmacies: [Pharmacy] = []
    @Published public var selectedPharmacy: Pharmacy? = nil
    @Published public var defaultPharmacy: Pharmacy? = nil
    
    public init(pharmacyService: PharmacyServiceProtocol) {
        self.pharmacyService = pharmacyService
    }
    
    // MARK: - Computed Properties
    
    public var hasPharmacies: Bool {
        return !pharmacies.isEmpty
    }
    
    public var hasDefaultPharmacy: Bool {
        return defaultPharmacy != nil
    }
    
    // MARK: - Methods
    
    /// Load pharmacies with optional search query
    public func loadPharmacies(query: String? = nil) async {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        
        do {
            let response = try await pharmacyService.searchPharmacies(query: query)
            
            if response.success {
                pharmacies = response.pharmacies
            } else {
                errorMessage = response.message ?? "Failed to load pharmacies"
                showErrorToast = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            pharmacies = []
        }
        
        isLoading = false
    }
    
    /// Create a new pharmacy
    public func createPharmacy(
        name: String,
        licenseNumber: String,
        address: String,
        city: String,
        state: String,
        postalCode: String,
        country: String,
        phone: String,
        email: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        showSuccessToast = false
        
        let data: [String: Any] = [
            "name": name,
            "license_number": licenseNumber,
            "address": address,
            "city": city,
            "state": state,
            "postal_code": postalCode,
            "country": country,
            "phone": phone,
            "email": email,
            "is_active": true
        ]
        
        do {
            let response = try await pharmacyService.createPharmacy(data: data)
            
            if response.success {
                // Reload pharmacies list to include the new pharmacy
                await loadPharmacies()
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to create pharmacy"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Update an existing pharmacy
    public func updatePharmacy(
        pharmacyId: String,
        name: String,
        licenseNumber: String,
        address: String,
        city: String,
        state: String,
        postalCode: String,
        country: String,
        phone: String,
        email: String
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        showSuccessToast = false
        
        let data: [String: Any] = [
            "name": name,
            "license_number": licenseNumber,
            "address": address,
            "city": city,
            "state": state,
            "postal_code": postalCode,
            "country": country,
            "phone": phone,
            "email": email,
            "is_active": true
        ]
        
        do {
            let response = try await pharmacyService.updatePharmacy(pharmacyId: pharmacyId, data: data)
            
            if response.success {
                // Reload pharmacies list to include the updated pharmacy
                await loadPharmacies()
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to update pharmacy"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Delete a pharmacy
    public func deletePharmacy(pharmacyId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        showSuccessToast = false
        
        do {
            let response = try await pharmacyService.deletePharmacy(pharmacyId: pharmacyId)
            
            if response.success {
                // Reload pharmacies list after deletion
                await loadPharmacies()
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to delete pharmacy"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    /// Set a pharmacy as default
    public func setDefaultPharmacy(pharmacyId: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        showErrorToast = false
        showSuccessToast = false
        
        do {
            let response = try await pharmacyService.setDefaultPharmacy(pharmacyId: pharmacyId)
            
            if response.success {
                // Reload pharmacies list to update default status
                await loadPharmacies()
                showSuccessToast = true
                isLoading = false
                return true
            } else {
                errorMessage = response.message ?? "Failed to set default pharmacy"
                showErrorToast = true
                isLoading = false
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorToast = true
            isLoading = false
            return false
        }
    }
    
    // TODO: Implement remaining pharmacy methods as features are developed
    // - loadPharmacyDetails(pharmacyId:)
}
