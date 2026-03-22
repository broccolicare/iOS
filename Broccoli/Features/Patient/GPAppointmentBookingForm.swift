//
//  GPAppointmentBookingForm.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 21/11/25.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct GPAppointmentBookingForm: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingViewModel: BookingGlobalViewModel
    @FocusState private var isTextEditorFocused: Bool
    
    // State variables
    @State private var selectedDate: Date? = Date()
    @State private var additionalDescription: String = ""
    @State private var currentMonth: Date = Date()
    @State private var showDocumentPicker = false
    @State private var showAttachmentOptions = false
    @State private var showPhotoPicker = false
    @State private var showCameraPicker = false
    
    // Computed property for selected time slot from view model
    private var selectedTimeSlot: String? {
        bookingViewModel.selectedTimeSlot
    }
    
    // Computed property to check if we should show error alert
    private var shouldShowErrorAlert: Binding<Bool> {
        Binding(
            get: {
                bookingViewModel.showErrorToast && 
                bookingViewModel.errorMessage != nil && 
                !bookingViewModel.errorMessage!.isEmpty
            },
            set: { newValue in
                bookingViewModel.showErrorToast = newValue
            }
        )
    }
    
    // Get all available slots combined
    private var allAvailableSlots: [TimeSlot] {
        bookingViewModel.morningSlots + bookingViewModel.afternoonSlots + bookingViewModel.eveningSlots
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { router.pop() }) {
                        Image("back-icon-white")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.colors.primary)
                    }
                    
                    Spacer()
                    
                    Text("Select Date")
                        .font(theme.typography.medium24)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Image("BackButton")
                        .font(.system(size: 16, weight: .semibold))
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(theme.colors.gradientStart)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Calendar Section
                        VStack(spacing: 16) {
                            // Month Navigation
                            VStack{
                                HStack {
                                    Button(action: { previousMonth() }) {
                                        Image(systemName: "chevron.left")
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(monthYearString(from: currentMonth))
                                        .font(theme.typography.semiBold18)
                                        .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Button(action: { nextMonth() }) {
                                        Image(systemName: "chevron.right")
                                            .foregroundStyle(.white)
                                            .frame(width: 32, height: 32)
                                    }
                                }
                                .padding(.vertical, 4)
                                .background(theme.colors.monthSwitcherBackgroundColor)
                                .cornerRadius(4)
                            }
                            .padding(.horizontal, 20)
                            
                            // Calendar Grid
                            VStack(spacing: 12) {
                                // Weekday headers
                                HStack(spacing: 0) {
                                    ForEach(Array(["S", "M", "T", "W", "T", "F", "S"].enumerated()), id: \.offset) { index, day in
                                        Text(day)
                                            .font(theme.typography.medium14)
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                // Calendar days
                                let days = generateCalendarDays(for: currentMonth)
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                                    ForEach(Array(days.enumerated()), id: \.offset) { index, date in
                                        if let date = date {
                                            DayCell(
                                                date: date,
                                                isSelected: selectedDate?.isSameDay(as: date) ?? false,
                                                isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month)
                                            ) {
                                                selectedDate = date
                                                bookingViewModel.selectedTimeSlot = nil // Reset time slot when date changes
                                                bookingViewModel.selectedDate = date
                                                
                                                // Fetch time slots for the new date
                                                Task {
                                                    await bookingViewModel.fetchAvailableTimeSlots()
                                                }
                                            }
                                        } else {
                                            Color.clear
                                                .frame(height: 40)
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [theme.colors.gradientStart, theme.colors.gradientEnd],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        // Available Slots Section
                        if selectedDate != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Available Slots")
                                    .font(theme.typography.semiBold18)
                                    .foregroundStyle(theme.colors.textPrimary)
                                    .padding(.horizontal, 20)
                                
                                if bookingViewModel.isLoading {
                                    // Loading state
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                } else if allAvailableSlots.isEmpty {
                                    // No slots available
                                    Text("No available slots for this date")
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 100)
                                        .padding(.horizontal, 20)
                                } else {
                                    VStack(alignment: .leading, spacing: 20) {
                                        // Morning Slots
                                        if !bookingViewModel.morningSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Morning")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.morningSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: true
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "morning"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Afternoon Slots
                                        if !bookingViewModel.afternoonSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Afternoon")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.afternoonSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: true
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "afternoon"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Evening Slots
                                        if !bookingViewModel.eveningSlots.isEmpty {
                                            VStack(alignment: .leading, spacing: 12) {
                                                Text("Evening")
                                                    .font(theme.typography.semiBold16)
                                                    .foregroundStyle(theme.colors.textPrimary)
                                                
                                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                                    ForEach(bookingViewModel.eveningSlots) { slot in
                                                        TimeSlotButton(
                                                            time: slot.displayTime,
                                                            price: formatPrice(slot.price),
                                                            isSelected: selectedTimeSlot == slot.time,
                                                            showPrice: true
                                                        ) {
                                                            bookingViewModel.selectedTimeSlot = slot.time
                                                            bookingViewModel.selectedTimeSlotPeriod = "evening"
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Upload Document Section (visible after selecting date and time)
                        if selectedDate != nil && selectedTimeSlot != nil {
                            VStack(alignment: .leading, spacing: 12) {
                                // Header row
                                HStack {
                                    Text("Documents")
                                        .font(theme.typography.semiBold16)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    Spacer()
                                    Text("\(bookingViewModel.pendingAttachments.count)/5")
                                        .font(theme.typography.regular12)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                                .padding(.horizontal, 20)

                                // Selected files list
                                ForEach(Array(bookingViewModel.pendingAttachments.enumerated()), id: \.element.id) { index, file in
                                    HStack(spacing: 10) {
                                        Image(systemName: fileIcon(for: file.mimeType))
                                            .font(.system(size: 16))
                                            .foregroundStyle(theme.colors.primary)
                                        Text(file.fileName)
                                            .font(theme.typography.regular14)
                                            .foregroundStyle(theme.colors.textPrimary)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                        Spacer()
                                        Button(action: { bookingViewModel.removePendingAttachment(at: index) }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundStyle(.gray.opacity(0.6))
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.96, green: 0.97, blue: 0.98))
                                    .cornerRadius(8)
                                    .padding(.horizontal, 20)
                                }

                                // Add file button (hidden when at max 5)
                                if bookingViewModel.pendingAttachments.count < 5 {
                                    Button(action: { showAttachmentOptions = true }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle")
                                                .font(.system(size: 18))
                                            Text(bookingViewModel.pendingAttachments.isEmpty
                                                 ? "Upload Document (optional)"
                                                 : "Add Another File")
                                                .font(theme.typography.regular14)
                                        }
                                        .foregroundStyle(theme.colors.primary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 60)
                                        .background(Color(red: 0.95, green: 0.97, blue: 0.98))
                                        .cornerRadius(12)
                                    }
                                    .padding(.horizontal, 20)
                                }

                                // Additional Descriptions
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Additional Descriptions")
                                        .font(theme.typography.semiBold16)
                                        .foregroundStyle(theme.colors.textPrimary)
                                    
                                    TextEditor(text: $additionalDescription)
                                        .font(theme.typography.regular14)
                                        .foregroundStyle(theme.colors.textPrimary)
                                        .frame(height: 120)
                                        .padding(12)
                                        .focused($isTextEditorFocused)
                                        .background(Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Bottom spacing
                        if selectedDate != nil && selectedTimeSlot != nil {
                            Color.clear.frame(height: 80)
                        } else {
                            Color.clear.frame(height: 20)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        hideKeyboard()
                    }
                }
                
                // Save & Next Button (visible after selecting date and time)
                if selectedDate != nil && selectedTimeSlot != nil {
                    Button(action: {
                        // Dismiss keyboard
                        hideKeyboard()
                        
                        // Save selected date, time slot and additional notes to view model
                        bookingViewModel.selectedDate = selectedDate
                        bookingViewModel.additionalNotes = additionalDescription
                        
                        // Navigate to booking confirmation to review before creating
                        router.push(.bookingConfirmation)
                    }) {
                        Text("Save & Next")
                            .font(theme.typography.button)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                    .background(theme.colors.primary)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .background(Color.white)
                }
            }
        }
        .confirmationDialog("Add Document", isPresented: $showAttachmentOptions) {
            Button("Camera") { showCameraPicker = true }
            Button("Photo Library") { showPhotoPicker = true }
            Button("Browse Files") { showDocumentPicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPicker { files in
                for file in files { bookingViewModel.addPendingAttachment(file) }
            }
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoLibraryPicker { file in
                bookingViewModel.addPendingAttachment(file)
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker { file in
                bookingViewModel.addPendingAttachment(file)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Reset booking form state first
            bookingViewModel.resetBookingForm()
            
            // Initialize view model with current date
            bookingViewModel.selectedDate = selectedDate
            
            // Set GP booking parameters
            bookingViewModel.isGP = "1"
            bookingViewModel.selectedDepartmentId = "1"
        }
        .task {
            // Use .task instead of .onAppear with Task to ensure proper lifecycle management
            // Add a small delay to let navigation settle
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            // First, fetch services for the department
            await bookingViewModel.loadDepartmentServices(departmentId: "1")
            
            // Then fetch time slots if date is selected and services loaded successfully
            if selectedDate != nil && !bookingViewModel.services.isEmpty {
                // Set the first service as selected if available
                if let firstService = bookingViewModel.services.first {
                    bookingViewModel.selectedService = firstService
                }
                await bookingViewModel.fetchAvailableTimeSlots()
            }
        }
        .alert("Error", isPresented: shouldShowErrorAlert) {
            Button("OK", role: .cancel) {
                bookingViewModel.errorMessage = nil
                bookingViewModel.showErrorToast = false
            }
        } message: {
            Text(bookingViewModel.errorMessage ?? "An unknown error occurred")
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatPrice(_ price: String?) -> String {
        guard let price = price else { return "N/A" }
        let currency = bookingViewModel.pricingInfo?.currency ?? "USD"
        let symbol: String
        switch currency {
        case "EUR": symbol = "€"
        case "GBP": symbol = "£"
        case "USD": symbol = "$"
        default: symbol = currency
        }
        return "\(symbol)\(price)"
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            currentMonth = newMonth
        }
    }
    
    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func fileIcon(for mimeType: String) -> String {
        if mimeType.hasPrefix("image/") { return "photo" }
        if mimeType == "application/pdf" { return "doc.richtext" }
        return "doc.fill"
    }

    private func generateCalendarDays(for month: Date) -> [Date?] {
        var days: [Date?] = []
        let calendar = Calendar.current
        
        // Get the first day of the month
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)),
              let monthRange = calendar.range(of: .day, in: .month, for: month) else {
            return days
        }
        
        // Get the weekday of the first day (0 = Sunday)
        let firstWeekday = calendar.component(.weekday, from: monthStart) - 1
        
        // Add nil for days before the month starts
        for _ in 0..<firstWeekday {
            days.append(nil)
        }
        
        // Add all days of the month
        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                days.append(date)
            }
        }
        
        // Add nil for remaining days to complete the grid
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
}

// MARK: - Photo Library Picker
struct PhotoLibraryPicker: UIViewControllerRepresentable {
    let onPicked: (AttachmentFile) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 5
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoLibraryPicker
        init(_ parent: PhotoLibraryPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            for result in results {
                result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                    guard let data else { return }
                    let fileName = (result.itemProvider.suggestedName ?? "photo") + ".jpg"
                    let file = AttachmentFile(fileName: fileName, mimeType: "image/jpeg", data: data)
                    DispatchQueue.main.async { self.parent.onPicked(file) }
                }
            }
        }
    }
}

// MARK: - Camera Picker
struct CameraPicker: UIViewControllerRepresentable {
    let onPicked: (AttachmentFile) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            picker.dismiss(animated: true)
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.8) else { return }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let fileName = "photo_\(formatter.string(from: Date())).jpg"
            let file = AttachmentFile(fileName: fileName, mimeType: "image/jpeg", data: data)
            parent.onPicked(file)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let onPicked: ([AttachmentFile]) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [
            .pdf, .jpeg, .png, .gif, .webP,
            UTType("com.microsoft.word.doc") ?? .data,
            UTType("org.openxmlformats.wordprocessingml.document") ?? .data
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            let files: [AttachmentFile] = urls.compactMap { url in
                guard url.startAccessingSecurityScopedResource() else { return nil }
                defer { url.stopAccessingSecurityScopedResource() }
                guard let data = try? Data(contentsOf: url) else { return nil }
                let mimeType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "application/octet-stream"
                return AttachmentFile(fileName: url.lastPathComponent, mimeType: mimeType, data: data)
            }
            parent.onPicked(files)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}
    }
}

// MARK: - Date Extension
extension Date {
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }
}

// MARK: - Preview
#Preview {
    GPAppointmentBookingForm()
        .environment(\.appTheme, AppTheme.default)
}
