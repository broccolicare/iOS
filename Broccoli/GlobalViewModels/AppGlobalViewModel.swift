//
//  AppViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//


import Foundation
import Combine

@MainActor
public final class AppGlobalViewModel: ObservableObject {
    // Published UI state
    @Published public private(set) var htmlContent: String? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    @Published var countryCodes: [CountryCode] = []
    @Published var specializations: [Specialization] = []
    @Published var slidersData: [Slider] = []
    
    // Metadata from API
    @Published public var bloodGroups: [BloodGroup] = []
    @Published public var allergyCategories: [AllergyCategory] = []
    @Published public var allergies: [MetadataAllergy] = []
    @Published public var genders: [Gender] = []
    @Published public private(set) var isMetadataLoaded: Bool = false
    
    private var fallbackCountryCodes: [CountryCode] = [
        CountryCode(id: 103, nicename: "Ireland", phoneCode: "353"),
    ]

    private let appService: AppServiceProtocol

    /// Simple in-memory cache for static pages (keeps previously fetched HTML).
    /// Keyed by StaticPageType.rawValue (or the enum itself if you prefer).
    private var cache: [StaticPageType: String] = [:]

    public init(appService: AppServiceProtocol) {
        self.appService = appService
    }
    
    // MARK: - Computed Properties for UI
    
    public var phoneCodesOnly: [String] {
        return countryCodes.map { $0.formattedPhoneCode }
    }
    
    public var countryNamesOnly: [String] {
        return countryCodes.map { $0.nicename }
    }
    
    public var specializationNamesOnly: [String] {
        return specializations.map { $0.name }
    }

    /// Load content for the requested static page.
    /// - parameter useCache: whether to return cached content immediately (default true)
    public func load(page: StaticPageType, useCache: Bool = true) async {
        // If cached and allowed, return immediately
        if useCache, let cached = cache[page] {
            self.htmlContent = cached
            self.errorMessage = nil
            return
        }

        isLoading = true
        errorMessage = nil
        htmlContent = nil

        do {
            let html = try await appService.fetchStaticPage(page)
            cache[page] = html
            self.htmlContent = html
        } catch {
            // Convert to readable message
            self.errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    /// Force refresh from API ignoring cache
    public func refresh(page: StaticPageType) async {
        await load(page: page, useCache: false)
    }

    /// Clear the in-memory cache (useful for logout or language change)
    public func clearCache() {
        cache.removeAll()
    }
    
    public func loadCountryCodes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let codes = try await appService.fetchCountryCodes()
            countryCodes = codes.isEmpty ? fallbackCountryCodes : codes
        } catch {
            errorMessage = "Failed to load country codes. Using default options."
            // Keep fallback codes if API fails
            countryCodes = fallbackCountryCodes
        }
        
        isLoading = false
    }
    
    public func loadSpecializations() async {
        do {
            let specs = try await appService.fetchSpecializations()
            specializations = specs.isEmpty ? [] : specs
        } catch {
            errorMessage = "Failed to load specialization."
            // Keep fallback specializations if API fails
            specializations = []
        }
    }
    
    public func loadMetadata() async {
        // Prevent loading multiple times
        guard !isMetadataLoaded else { return }
        
        do {
            let response = try await appService.fetchMetaData()
            let metadata = response.data
            
            // Store all metadata
            bloodGroups = metadata.bloodGroups
            allergyCategories = metadata.allergyCategories
            allergies = metadata.allergies
            genders = metadata.genders
            
            isMetadataLoaded = true
            
            print("✅ Metadata loaded successfully")
            print("   - Blood Groups: \(bloodGroups.count)")
            print("   - Allergy Categories: \(allergyCategories.count)")
            print("   - Allergies: \(allergies.count)")
            print("   - Genders: \(genders.count)")
        } catch {
            errorMessage = "Failed to load metadata: \(error.localizedDescription)"
            print("❌ Failed to load metadata: \(error)")
            
            // Set default values as fallback
            genders = [
                Gender(value: "male", label: "Male"),
                Gender(value: "female", label: "Female"),
                Gender(value: "other", label: "Other")
            ]
        }
    }
    
    public func loadSlidersData() async {
        do {
            let sliders = try await appService.fetchSlidersData()
            slidersData = sliders
            print("✅ Sliders data loaded successfully: \(sliders.count) items")
        } catch {
            errorMessage = "Failed to load sliders data: \(error.localizedDescription)"
            print("❌ Failed to load sliders data: \(error)")
            slidersData = []
        }
    }
}
