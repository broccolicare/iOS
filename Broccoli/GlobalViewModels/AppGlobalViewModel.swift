//
//  AppViewModel.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//


import Foundation
import Combine
import FirebaseMessaging
import UIKit

@MainActor
public final class AppGlobalViewModel: ObservableObject {
    // Published UI state
    @Published public private(set) var htmlContent: String? = nil
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String? = nil
    
    @Published var countryCodes: [CountryCode] = []
    @Published var specializations: [Specialization] = []
    @Published var slidersData: [Slider] = []
    @Published var medicalProcedures: [MedicalProcedure] = []
    @Published var medicalDestinations: [MedicalDestination] = []
    @Published var recoveryDrugs: [RecoveryDrug] = []
    @Published var recoveryAddictionYears: [RecoveryAddictionYear] = []
    @Published var allServices: [Service] = []
    
    // Metadata from API
    @Published public var bloodGroups: [BloodGroup] = []
    @Published public var allergyCategories: [AllergyCategory] = []
    @Published public var allergies: [MetadataAllergy] = []
    @Published public var genders: [Gender] = []
    @Published public private(set) var isMetadataLoaded: Bool = false
    
    private var fallbackCountryCodes: [CountryCode] = [
        CountryCode(id: 103, nicename: "Ireland", iso: "IE", iso3: "IRL", phoneCode: "353"),
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
            let response = try await appService.fetchSlidersData()
            slidersData = response.data
            print("✅ Sliders data loaded successfully: \(response.data.count) items")
        } catch {
            errorMessage = "Failed to load sliders data: \(error.localizedDescription)"
            print("❌ Failed to load sliders data: \(error)")
            slidersData = []
        }
    }
    
    public func loadMedicalProcedures() async {
        do {
            let procedures = try await appService.fetchMedicalProcedures()
            medicalProcedures = procedures
            print("✅ Medical procedures loaded successfully: \(procedures.count) items")
        } catch {
            errorMessage = "Failed to load medical procedures: \(error.localizedDescription)"
            print("❌ Failed to load medical procedures: \(error)")
            medicalProcedures = []
        }
    }
    
    public func loadMedicalDestinations() async {
        do {
            let destinations = try await appService.fetchMedicalDestinations()
            medicalDestinations = destinations
            print("✅ Medical destinations loaded successfully: \(destinations.count) items")
        } catch {
            errorMessage = "Failed to load medical destinations: \(error.localizedDescription)"
            print("❌ Failed to load medical destinations: \(error)")
            medicalDestinations = []
        }
    }
    
    public func loadRecoveryDrugs() async {
        do {
            let drugs = try await appService.fetchRecoveryDrugs()
            recoveryDrugs = drugs
            print("✅ Recovery drugs loaded successfully: \(drugs.count) items")
        } catch {
            errorMessage = "Failed to load recovery drugs: \(error.localizedDescription)"
            print("❌ Failed to load recovery drugs: \(error)")
            recoveryDrugs = []
        }
    }
    
    public func loadRecoveryAddictionYears() async {
        do {
            let years = try await appService.fetchRecoveryAddictionYears()
            recoveryAddictionYears = years
            print("✅ Recovery addiction years loaded successfully: \(years.count) items")
        } catch {
            errorMessage = "Failed to load recovery addiction years: \(error.localizedDescription)"
            print("❌ Failed to load recovery addiction years: \(error)")
            recoveryAddictionYears = []
        }
    }
    
    public func loadAllServices() async {
        do {
            let services = try await appService.fetchAllServices()
            allServices = services
            print("✅ All services loaded successfully: \(services.count) items")
        } catch {
            errorMessage = "Failed to load services: \(error.localizedDescription)"
            print("❌ Failed to load services: \(error)")
            allServices = []
        }
    }
    
    // MARK: - Contact Us
    
    @Published public var isSubmittingContact: Bool = false
    @Published public var contactSubmitSuccess: Bool = false
    
    public func submitContactForm(name: String, email: String, phone: String? = nil, subject: String, message: String) async -> Bool {
        isSubmittingContact = true
        errorMessage = nil
        
        do {
            let response = try await appService.submitContactForm(
                name: name,
                email: email,
                phone: phone,
                subject: subject,
                message: message
            )
            isSubmittingContact = false
            if response.data != nil {
                contactSubmitSuccess = true
                print("✅ Contact form submitted successfully")
                return true
            } else {
                errorMessage = response.message ?? "Failed to submit contact form"
                return false
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to submit contact form: \(error)")
            isSubmittingContact = false
            return false
        }
    }
    
    // MARK: - Device Token Registration
    
    public func registerDeviceToken() async {
        guard let fcmToken = Messaging.messaging().fcmToken else {
            print("⚠️ FCM token not available yet — skipping device token registration")
            return
        }
        
        let deviceName = UIDevice.current.name
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        
        do {
            let response = try await appService.registerDeviceToken(
                token: fcmToken,
                deviceName: deviceName,
                appVersion: appVersion
            )
            print("✅ Device token registered: \(response.message ?? "success")")
        } catch {
            print("❌ Failed to register device token: \(error)")
        }
    }
    
    // MARK: - Notifications
    
    @Published public var notifications: [AppNotification] = []
    @Published public var unreadNotificationsCount: Int = 0
    @Published public var isLoadingNotifications: Bool = false
    
    public func fetchNotifications() async {
        isLoadingNotifications = true
        do {
            let response = try await appService.fetchNotifications()
            notifications = response.notifications?.data ?? []
            unreadNotificationsCount = response.unreadCount ?? 0
            print("✅ Notifications loaded: \(notifications.count) items, unread: \(unreadNotificationsCount)")
        } catch {
            print("❌ Failed to load notifications: \(error)")
            notifications = []
        }
        isLoadingNotifications = false
    }
}
