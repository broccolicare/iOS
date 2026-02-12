//
//  PrescriptionQuestionsView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/12/25.
//

import SwiftUI
@_spi(CustomerSessionBetaAccess) import StripePaymentSheet

struct PrescriptionQuestionsView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    
    @State private var currentStep: Int = 1
    @State private var showPaymentSheet = false
    @State private var questionValidationErrors: Set<Int> = []
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { handleBackButton() }) {
                        Image("BackButton")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Book Prescription")
                        .font(theme.typography.medium20)
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
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 8) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background bar
                            Rectangle()
                                .fill(Color(red: 0.9, green: 0.93, blue: 0.95))
                                .frame(height: 6)
                            
                            // Progress bar
                            Rectangle()
                                .fill(theme.colors.primary)
                                .frame(width: geometry.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("Step \(currentStep) / \(totalSteps)")
                        .font(theme.typography.regular12)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Content
                if bookingViewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Spacer()
                } else if let questionnaire = bookingViewModel.currentQuestionnaire,
                          currentStep <= questionnaire.questionnaireGroups.count,
                          let currentGroup = questionnaire.questionnaireGroups.first(where: { $0.order == currentStep }) {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Title
                            Text(currentGroup.title)
                                .font(theme.typography.bold28)
                                .foregroundStyle(theme.colors.textPrimary)
                            
                            // Subtitle
                            if let description = currentGroup.description {
                                Text(description)
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                            } else {
                                Text("Please answer all questions below.")
                                    .font(theme.typography.regular14)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                            
                            // Dynamic Questions from API
                            VStack(alignment: .leading, spacing: 24) {
                                ForEach(Array(currentGroup.questions.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { index, question in
                                    QuestionnaireQuestionView(
                                        number: index + 1,
                                        question: question,
                                        selectedOptions: Binding(
                                            get: { bookingViewModel.questionnaireAnswers[question.id] ?? [] },
                                            set: { bookingViewModel.questionnaireAnswers[question.id] = $0 }
                                        ),
                                        textAnswer: Binding(
                                            get: { bookingViewModel.questionnaireTextAnswers[question.id] ?? "" },
                                            set: { bookingViewModel.questionnaireTextAnswers[question.id] = $0 }
                                        ),
                                        hasError: questionValidationErrors.contains(question.id)
                                    )
                                }
                            }
                            
                            // Next/Submit Button
                            Button(action: {
                                handleSubmit()
                            }) {
                                Text(currentStep < totalSteps ? "Next" : "Submit")
                                    .font(theme.typography.button)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(theme.colors.primary)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 32)
                            
                            // Bottom spacing
                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                } else {
                    Spacer()
                    Text("No questionnaire available")
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textSecondary)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await fetchQuestionnaire()
        }
        .paymentSheet(
            isPresented: $showPaymentSheet,
            paymentSheet: bookingViewModel.paymentSheet ?? PaymentSheet(paymentIntentClientSecret: "", configuration: PaymentSheet.Configuration())
        ) { result in
            Task {
                // Handle payment completion for prescription
                let response = await bookingViewModel.onPrescriptionPaymentCompletion(result: result)
                
                if response?.success == true {
                    // Payment confirmed successfully - navigate to success screen
                    router.push(.paymentSuccess(booking: nil))
                }
                
                // Reset payment sheet
                bookingViewModel.paymentSheet = nil
                bookingViewModel.isPaymentReady = false
                showPaymentSheet = false
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var totalSteps: Int {
        bookingViewModel.currentQuestionnaire?.questionnaireGroups.count ?? 5
    }
    
    private func fetchQuestionnaire() async {
        guard let selectedPrescription = bookingViewModel.selectedPrescription else { return }
        await bookingViewModel.fetchTreatmentQuestionnaire(treatmentId: selectedPrescription.id)
    }
    
    private func getSelectedTreatment() -> Treatment? {
        guard let selectedPrescription = bookingViewModel.selectedPrescription,
              let treatmentId = Int(selectedPrescription.id) else {
            return nil
        }
        return bookingViewModel.treatments.first { $0.id == treatmentId }
    }
    
    private func extractTreatmentType(from name: String) -> String {
        let cleanedName = name.replacingOccurrences(of: " Treatment", with: "")
        return cleanedName
    }
    
    private func handleBackButton() {
        if currentStep > 1 {
            // Go to previous step
            currentStep -= 1
        } else {
            // Navigate back to previous screen
            router.pop()
        }
    }
    
    private func handleSubmit() {
        // Validate current step before proceeding
        if !validateCurrentStep() {
            return
        }
        
        if currentStep < totalSteps {
            // Move to next step
            currentStep += 1
        } else {
            // Final submission - create prescription order
            Task {
                print("📝 [View] Submitting prescription order...")
                let success = await bookingViewModel.createPrescriptionOrder()
                print("📝 [View] Prescription order result: \(success)")
                print("📝 [View] isPaymentReady: \(bookingViewModel.isPaymentReady)")
                print("📝 [View] requiresPayment: \(bookingViewModel.requiresPayment)")
                
                if success {
                    // Check if payment sheet is ready (payment required and not covered by subscription)
                    if bookingViewModel.isPaymentReady && bookingViewModel.requiresPayment {
                        // Show payment sheet
                        print("📝 [View] Showing payment sheet")
                        showPaymentSheet = true
                    } else {
                        // No payment required or covered by subscription - navigate to success
                        print("📝 [View] Navigating to success (no payment needed)")
                        router.push(.paymentSuccess(booking: nil))
                    }
                } else {
                    print("📝 [View] Prescription order failed")
                }
            }
        }
    }
    
    private func validateCurrentStep() -> Bool {
        guard let questionnaire = bookingViewModel.currentQuestionnaire,
              let currentGroup = questionnaire.questionnaireGroups.first(where: { $0.order == currentStep }) else {
            return true
        }
        
        // Clear previous validation errors
        questionValidationErrors.removeAll()
        
        // Check all required questions in current step
        for question in currentGroup.questions where question.isRequired {
            let questionType = question.questionType.lowercased()
            
            switch questionType {
            case "single_choice", "singlechoice", "multiple_choice", "multiplechoice":
                // Check if option is selected
                let selectedOptions = bookingViewModel.questionnaireAnswers[question.id] ?? []
                if selectedOptions.isEmpty {
                    questionValidationErrors.insert(question.id)
                }
                
            case "text", "text_input", "textinput":
                // Check if text is not empty
                let textAnswer = bookingViewModel.questionnaireTextAnswers[question.id] ?? ""
                if textAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    questionValidationErrors.insert(question.id)
                }
                
            default:
                break
            }
        }
        
        return questionValidationErrors.isEmpty
    }
}

// MARK: - Questionnaire Question View Component
struct QuestionnaireQuestionView: View {
    @Environment(\.appTheme) private var theme
    let number: Int
    let question: QuestionnaireQuestion
    @Binding var selectedOptions: [Int]
    @Binding var textAnswer: String
    let hasError: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Question Text
            HStack(spacing: 4) {
                Text("\(number). \(question.questionText)")
                    .font(theme.typography.regular16)
                    .foregroundStyle(hasError ? .red : theme.colors.textPrimary)
                
                if question.isRequired {
                    Text("*")
                        .font(theme.typography.regular16)
                        .foregroundStyle(.red)
                }
            }
            
            // Answer Options based on question type
            switch question.questionType.lowercased() {
            case "multiple_choice", "multiplechoice":
                // Multiple selection - button group
                FlowLayout(spacing: 12) {
                    ForEach(question.options.sorted(by: { $0.order < $1.order })) { option in
                        MultipleChoiceOption(
                            option: option,
                            isSelected: selectedOptions.contains(option.id)
                        ) {
                            toggleMultipleChoice(optionId: option.id)
                        }
                    }
                }
                
            case "single_choice", "singlechoice":
                // Single selection - button group
                FlowLayout(spacing: 12) {
                    ForEach(question.options.sorted(by: { $0.order < $1.order })) { option in
                        SingleChoiceOption(
                            option: option,
                            isSelected: selectedOptions.first == option.id
                        ) {
                            selectedOptions = [option.id]
                        }
                    }
                }
                
            case "text", "text_input", "textinput":
                // Text input
                TextEditor(text: $textAnswer)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                    )
                    .cornerRadius(8)
                
            default:
                Text("Unknown question type")
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            
            // Error Message
            if hasError {
                Text("Please answer this question")
                    .font(theme.typography.regular12)
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }
        }
    }
    
    private func toggleMultipleChoice(optionId: Int) {
        if selectedOptions.contains(optionId) {
            selectedOptions.removeAll { $0 == optionId }
        } else {
            selectedOptions.append(optionId)
        }
    }
}

// MARK: - Multiple Choice Option Component
struct MultipleChoiceOption: View {
    @Environment(\.appTheme) private var theme
    let option: QuestionOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option.optionText)
                .font(theme.typography.regular14)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? theme.colors.primary : .white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isSelected ? theme.colors.primary : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Single Choice Option Component
struct SingleChoiceOption: View {
    @Environment(\.appTheme) private var theme
    let option: QuestionOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(option.optionText)
                .font(theme.typography.regular14)
                .foregroundStyle(isSelected ? .white : theme.colors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? theme.colors.primary : .white)
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(isSelected ? theme.colors.primary : Color(red: 0.9, green: 0.9, blue: 0.9), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    PrescriptionQuestionsView()
        .environmentObject(Router.shared)
        .environmentObject(BookingGlobalViewModel(bookingService: BookingService(httpClient: HTTPClient())))
        .environment(\.appTheme, AppTheme.default)
}
