//
//  BroccoliApp.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 07/10/25.
//

import SwiftUI
import StripePaymentSheet

@main
struct BroccoliApp: App {
    
    // Dependencies are created within the StateObject closures to avoid capturing self during App init
    
    @StateObject private var router = Router.shared
    
    @StateObject private var authViewModel: AuthGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let secureStore = SecureStore() as any SecureStoreProtocol
        let authService = AuthService(httpClient: httpClient, secureStore: secureStore)
        return AuthGlobalViewModel(authService: authService, secureStore: secureStore)
    }()
    
    @StateObject private var appViewModel: AppGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let appService = AppService(httpClient: httpClient)
        return AppGlobalViewModel(appService: appService)
    }()
    
    @StateObject private var userViewModel: UserGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let userService = UserService(httpClient: httpClient)
        return UserGlobalViewModel(userService: userService)
    }()
    
    @StateObject private var bookingViewModel: BookingGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let bookingService = BookingService(httpClient: httpClient)
        return BookingGlobalViewModel(bookingService: bookingService)
    }()
    
    @StateObject private var pharmacyViewModel: PharmacyGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let pharmacyService = PharmacyService(httpClient: httpClient)
        return PharmacyGlobalViewModel(pharmacyService: pharmacyService)
    }()
    
    @StateObject private var packageViewModel: PackageGlobalViewModel = {
        let httpClient = HTTPClient() as any HTTPClientProtocol
        let packageService = PackageService(httpClient: httpClient)
        return PackageGlobalViewModel(packageService: packageService)
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path){
                AppRootView()
                    .onReceive(NotificationCenter.default.publisher(for: .unauthorizedErrorReceived)) { _ in
                        // Handle 401 error - logout user and redirect to login
                        Task { @MainActor in
                            print("🔐 401 Unauthorized error detected - logging out user")
                            await authViewModel.forceLogout()
                            router.popToRoot()
                            router.push(.login)
                        }
                    }
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .welcome:
                            WelcomeView()
                        case .login:
                            LoginView()
                        case .signup(let origin, let userType):
                            SignUpView(origin: origin, selectedUserType: userType)
                        case .home:
                            // Route to appropriate home screen based on user type
                            if let user = authViewModel.currentUser, let role = user.primaryRole {
                                switch role {
                                case .patient:
                                    PatientRootTabView()
                                case .doctor:
                                    DoctorHomeView()
                                }
                            } else {
                                WelcomeView()
                            }
                        case .profile:
                            ProfileView()
                        case .doctorProfile:
                            DoctorProfileView()
                        case .booking(id: let id):
                            EmptyView()
                        case .staticPage(type: let type):
                            StaticPageView(pageType: type)
                        case .otp(phoneDisplay: let phoneDisplay, from: let otpSource):
                            OTPVerificationView(phoneDisplay: phoneDisplay, from: otpSource)
                        case .signupSuccess:
                            SignUpSuccessView()
                        case .resetPassword(email: let email, otp: let otp):
                            ResetPasswordView(email: email, otp: otp)
                        case .patientProfileDetail:
                            PatientProfileDetailView()
                        case .doctorProfileDetail:
                            DoctorProfileDetailView()
                        case .editPatientProfile:
                            EditPatientProfileView()
                        case .editDoctorProfile:
                            EditDoctorProfileView()
                        case .gPAppointBookingForm:
                            GPAppointmentBookingForm()
                        case .bookingConfirmation:
                            BookingConfirmationView()
                        case .specialistList(departmentId: let departmentId):
                            SpecialtyListView(departmentId: departmentId)
                        case .specilistBookingForm
                            : SpecialistBookingFormView()
                        case .paymentSuccess(booking: let booking):
                            PaymentSuccessView(booking: booking)
                        case .medicalTourisimForm:
                            MedicalEnquiryView()
                        case .cureFromDrugForm:
                            CureFromDrugView()
                        case .notifications:
                            NotificationsView()
                        case .myAppointments:
                            MyAppointmentsView()
                        case .myPharmacies:
                            MyPharmaciesView()
                        case .addPharmacy:
                            AddPharmacyView()
                        case .editPharmacy(let pharmacy):
                            EditPharmacyView(pharmacy: pharmacy)
                        case .bookPrescription:
                            BookPrescriptionView()
                        case .prescriptionQuestions:
                            PrescriptionQuestionsView()
                        case .settings:
                            SettingsView()
                        case .appointmentDetailForDoctor(let booking):
                            AppointmentDetailForDoctorView(booking: booking)
                        }
                    }
            }
            
            .environmentObject(router)
            .environmentObject(authViewModel)
            .environmentObject(appViewModel)
            .environmentObject(userViewModel)
            .environmentObject(bookingViewModel)
            .environmentObject(pharmacyViewModel)
            .environmentObject(packageViewModel)
            .environment(\.appTheme, AppTheme.default)
            .onOpenURL { incomingURL in
                // Handle Stripe redirect URLs
                let stripeHandled = StripeAPI.handleURLCallback(with: incomingURL)
                if !stripeHandled {
                    // Handle other URLs if needed
                    print("URL not handled by Stripe: \\(incomingURL)")
                }
            }
        }
    }
}
