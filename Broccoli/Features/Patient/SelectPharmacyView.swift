//
//  SelectPharmacyView.swift
//  Broccoli
//
//  Part of the prescription booking flow.
//  Shown after the patient completes the questionnaire.
//  The patient may optionally choose a pharmacy, then
//  taps "Pay Now" which creates the prescription order,
//  initialises payment and opens the Stripe payment sheet.
//

import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

struct SelectPharmacyView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @EnvironmentObject private var pharmacyVM: PharmacyGlobalViewModel

    @State private var selectedPharmacy: Pharmacy? = nil
    @State private var showPaymentSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }

                    Spacer()

                    Text("Select Pharmacy")
                        .font(theme.typography.medium20)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    Circle().fill(.clear).frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: Title + subtitle
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Choose a Pharmacy")
                                .font(theme.typography.bold28)
                                .foregroundStyle(theme.colors.textPrimary)

                            Text("Optionally select a preferred pharmacy for your prescription delivery.")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.textSecondary)
                        }

                        // MARK: Pharmacy Dropdown (optional)
                        if pharmacyVM.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding(.vertical, 12)
                                Spacer()
                            }
                        } else {
                            DropdownField(
                                selectedValue: $selectedPharmacy,
                                items: pharmacyVM.pharmacies,
                                placeholder: "Select pharmacy (optional)",
                                title: "Pharmacy",
                                allowsSearch: true
                            )

                            if pharmacyVM.pharmacies.isEmpty {
                                Text("No pharmacies available. You can continue without selecting one.")
                                    .font(theme.typography.regular12)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }

                            // Add new pharmacy link
                            Button(action: { router.push(.addPharmacy) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Add New Pharmacy")
                                        .font(theme.typography.regular14)
                                }
                                .foregroundStyle(theme.colors.primary)
                            }
                            .padding(.top, 2)
                        }

                        if let selected = selectedPharmacy {
                            // Selected pharmacy detail pill
                            HStack(spacing: 10) {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundStyle(theme.colors.primary)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.name)
                                        .font(theme.typography.medium14)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    if let address = selected.address {
                                        Text(address)
                                            .font(theme.typography.regular12)
                                            .foregroundStyle(theme.colors.textSecondary)
                                    }
                                }
                                Spacer()
                                Button(action: { selectedPharmacy = nil }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(theme.colors.textSecondary.opacity(0.6))
                                }
                            }
                            .padding(12)
                            .background(theme.colors.primary.opacity(0.06))
                            .cornerRadius(10)
                        }

                        Spacer(minLength: 32)

                        // MARK: Pay Now button
                        Button(action: initiatePayment) {
                            if bookingVM.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(theme.colors.primary)
                                    .cornerRadius(12)
                            } else {
                                Text("Pay Now")
                                    .font(theme.typography.button)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(theme.colors.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(bookingVM.isLoading)

                        // MARK: Skip pharmacy link
                        Button(action: {
                            selectedPharmacy = nil
                            initiatePayment()
                        }) {
                            Text("Continue without pharmacy")
                                .font(theme.typography.regular14)
                                .foregroundStyle(theme.colors.primary)
                                .underline()
                                .frame(maxWidth: .infinity)
                        }
                        .disabled(bookingVM.isLoading)
                        .opacity(selectedPharmacy == nil ? 0 : 1) // only visible when a pharmacy is selected
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await pharmacyVM.loadPharmacies()
        }
        // MARK: Stripe payment sheet
        .paymentSheet(
            isPresented: $showPaymentSheet,
            paymentSheet: bookingVM.paymentSheet ?? PaymentSheet(
                paymentIntentClientSecret: "",
                configuration: PaymentSheet.Configuration()
            )
        ) { result in
            Task {
                let response = await bookingVM.onPrescriptionPaymentCompletion(result: result)
                if response?.success == true {
                    router.push(.paymentSuccess(booking: nil))
                }
                bookingVM.paymentSheet = nil
                bookingVM.isPaymentReady = false
                showPaymentSheet = false
            }
        }
        .alert("Error", isPresented: $bookingVM.showErrorToast) {
            Button("OK", role: .cancel) { bookingVM.errorMessage = nil }
        } message: {
            Text(bookingVM.errorMessage ?? "")
        }
    }

    // MARK: - Private

    private func initiatePayment() {
        Task {
            let success = await bookingVM.createPrescriptionOrder(
                pharmacyId: selectedPharmacy?.id
            )

            guard success else { return }

            if bookingVM.isPaymentReady && bookingVM.requiresPayment {
                showPaymentSheet = true
            } else {
                // Covered by subscription or no payment required
                router.push(.paymentSuccess(booking: nil))
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SelectPharmacyView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environmentObject(PharmacyGlobalViewModel(pharmacyService: PharmacyService(httpClient: HTTPClient())))
}
