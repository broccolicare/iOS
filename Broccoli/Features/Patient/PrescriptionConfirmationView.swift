//
//  PrescriptionConfirmationView.swift
//  Broccoli
//
//  Shown after the patient picks a pharmacy (or skips it) for a prescription
//  purchase. Mirrors BookingConfirmationView's promo code + summary + pay
//  layout, but creates the prescription order and drives the prescription
//  payment endpoints instead of the booking ones.
//

import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

struct PrescriptionConfirmationView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel
    @EnvironmentObject private var userVM: UserGlobalViewModel

    @State private var isShowingPaymentSheet = false

    // Computed properties from view models
    private var patientName: String {
        userVM.profileData?.name ?? "Guest User"
    }

    private var patientPhone: String {
        if let code = userVM.profileData?.profile?.phoneCode,
           let phone = userVM.profileData?.profile?.phone {
            return "\(code) \(phone)"
        }
        return "Not provided"
    }

    private var patientEmail: String {
        userVM.profileData?.email ?? "Not provided"
    }

    private var treatmentName: String {
        bookingVM.currentQuestionnaire?.name ?? "Prescription"
    }

    private var pharmacyName: String {
        bookingVM.selectedPharmacyForPrescription?.name ?? "Not selected"
    }

    private func formatPrice(_ price: String) -> String {
        return "€\(price)"
    }

    private var rawTreatmentAmount: Double {
        guard let price = bookingVM.currentQuestionnaire?.price, let value = Double(price) else { return 0 }
        return value
    }

    private var treatmentCharge: String {
        guard let price = bookingVM.currentQuestionnaire?.price else { return "N/A" }
        return formatPrice(price)
    }

    private var totalPrice: String {
        treatmentCharge
    }

    private var discountedTotal: String {
        let discounted = max(rawTreatmentAmount - bookingVM.couponDiscountAmount, 0)
        return formatPrice(String(format: "%.2f", discounted))
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("BackButton")
                    }

                    Spacer()

                    Text("Confirmation Detail")
                        .font(theme.typography.medium24)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    // Invisible spacer for centering
                    Image("back-icon-white")
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .top) {

                        VStack {
                            Spacer().frame(height: 280)

                            // Promo Code Section
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    TextField("Enter promo code", text: $bookingVM.couponCode)
                                        .textInputAutocapitalization(.characters)
                                        .disableAutocorrection(true)
                                        .font(theme.typography.body)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .padding(.vertical, 14)
                                        .padding(.horizontal, 12)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: theme.cornerRadius)
                                                .stroke(theme.colors.border, lineWidth: 1)
                                        )
                                        .cornerRadius(theme.cornerRadius)
                                        .onChange(of: bookingVM.couponCode) { _, _ in
                                            if bookingVM.isCouponApplied {
                                                bookingVM.isCouponApplied = false
                                                bookingVM.couponMessage = nil
                                                bookingVM.couponDiscountAmount = 0
                                            }
                                            bookingVM.couponErrorMessage = nil
                                        }

                                    Button(action: {
                                        Task {
                                            await bookingVM.validateCoupon(
                                                amount: rawTreatmentAmount,
                                                purchaseType: "prescription",
                                                entityId: bookingVM.currentQuestionnaire?.id
                                            )
                                        }
                                    }) {
                                        Group {
                                            if bookingVM.isCouponLoading {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            } else {
                                                Text(bookingVM.isCouponApplied ? "Applied" : "Apply")
                                                    .font(theme.typography.button)
                                                    .multilineTextAlignment(.center)
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .frame(width: 88, height: 48)
                                    }
                                    .background(bookingVM.isCouponApplied ? theme.colors.textSecondary : theme.colors.primary)
                                    .cornerRadius(theme.cornerRadius)
                                    .disabled(bookingVM.isCouponApplied || bookingVM.isCouponLoading || bookingVM.couponCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                                }

                                if let message = bookingVM.couponMessage {
                                    Text(message)
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.lightGreen)
                                } else if let error = bookingVM.couponErrorMessage {
                                    Text(error)
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.error)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 8)

                            // Prescription Summary Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Prescription Summary")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)

                                VStack(spacing: 12) {
                                    SummaryRow(label: "Treatment :", value: treatmentName)
                                    SummaryRow(label: "Pharmacy :", value: pharmacyName)
                                }
                            }
                            .cornerRadius(12)
                            .padding(.horizontal, 20)

                            // Services Charge Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Services Charge")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)

                                VStack(spacing: 12) {
                                    ChargeRow(label: treatmentName, value: treatmentCharge)

                                    if bookingVM.isCouponApplied && bookingVM.couponDiscountAmount > 0 {
                                        ChargeRow(
                                            label: "Coupon discount",
                                            value: "-\(formatPrice(String(format: "%.2f", bookingVM.couponDiscountAmount)))",
                                            valueColor: theme.colors.lightGreen
                                        )
                                    }
                                }
                            }
                            .padding(.vertical, 20)
                            .padding(.horizontal, 20)

                            // Final Price
                            HStack {
                                Text(bookingVM.isCouponApplied ? "Total after discount" : "Final Price")
                                    .font(theme.typography.semiBold22)
                                    .foregroundStyle(theme.colors.primary)

                                Spacer()

                                Text(bookingVM.isCouponApplied ? discountedTotal : totalPrice)
                                    .font(theme.typography.semiBold22)
                                    .foregroundStyle(theme.colors.primary)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            // Bottom spacing for button
                            Color.clear.frame(height: 10)
                        }
                        .background(theme.colors.otpInputBox)
                        .border(theme.colors.orderConfirmationBorderColor)
                        .cornerRadius(16)


                        // Clinic Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Broccoli Care")
                                        .font(theme.typography.bold20)
                                        .foregroundStyle(.white)

                                    Text("Block A2, apartment, Louisa Park\nApartment 12, Leixlip, Co. Kildare, W23\nP584, Ireland, W23 P584, Leixlip, Ireland")
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(.white)
                                        .lineSpacing(4)
                                }

                                Spacer()

                                // Logo
                                Circle()
                                    .fill(.white)
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Text("B")
                                            .font(theme.typography.bold30)
                                            .foregroundStyle(theme.colors.primary)
                                    )
                            }

                            Divider()
                                .background(.white.opacity(0.3))
                                .padding(.vertical, 4)

                            // Patient Info
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Patient info")
                                    .font(theme.typography.bold18)
                                    .foregroundStyle(.white)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(patientName)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)

                                    Text(patientPhone)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)

                                    Text(patientEmail)
                                        .font(theme.typography.regular16)
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .padding(20)
                        .background(
                            theme.colors.primary
                        )
                        .overlay(
                            // Zigzag bottom border
                            ZigzagShape()
                                .fill(theme.colors.otpInputBox)
                                .frame(height: 20)
                                .offset(y: 12),
                            alignment: .bottom
                        )
                    }
                    .cornerRadius(12)

                }
                .padding(.top, 20)
                .padding(.horizontal, 20)

                // Confirm & Pay Button
                Button(action: {
                    Task {
                        let success = await bookingVM.createPrescriptionOrder(
                            pharmacyId: bookingVM.selectedPharmacyForPrescription?.id
                        )

                        guard success else { return }

                        if bookingVM.isPaymentReady && bookingVM.requiresPayment {
                            isShowingPaymentSheet = true
                        } else {
                            // Covered by subscription or no payment required
                            router.push(.paymentSuccess(booking: nil))
                        }
                    }
                }) {
                    if bookingVM.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    } else {
                        Text("Confirm & Pay")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(theme.colors.primary)
                .cornerRadius(12)
                .disabled(bookingVM.isLoading)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .paymentSheet(
            isPresented: $isShowingPaymentSheet,
            paymentSheet: bookingVM.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        ) { result in
            Task {
                let response = await bookingVM.onPrescriptionPaymentCompletion(result: result)

                if response?.success == true {
                    router.push(.paymentSuccess(booking: nil))
                }

                // Reset payment sheet
                bookingVM.paymentSheet = nil
                bookingVM.isPaymentReady = false
                isShowingPaymentSheet = false
            }
        }
        .alert("Error", isPresented: $bookingVM.showErrorToast) {
            Button("OK", role: .cancel) {
                bookingVM.errorMessage = nil
            }
        } message: {
            if let errorMessage = bookingVM.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PrescriptionConfirmationView()
        .environment(\.appTheme, AppTheme.default)
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environmentObject(UserGlobalViewModel(userService: UserService(httpClient: HTTPClient())))
}
