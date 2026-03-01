//
//  DoctorNotesFormView.swift
//  Broccoli
//
//  Created by AI Assistant on 16/02/26.
//

import SwiftUI

struct DoctorNotesFormView: View {
    @Environment(\.appTheme) private var theme
    @Binding var notes: String
    @Binding var isPresented: Bool
    /// Called when the doctor confirms. Returns `true` on success so the form
    /// can stay visible and show an error when the API fails.
    let onEndCall: (String) async -> Bool
    
    @State private var showValidationError: Bool = false
    @State private var isLoading: Bool = false
    @State private var apiError: String? = nil
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: theme.spacing.lg) {
                // Title
                Text("Consultation Notes")
                    .font(theme.typography.title)
                    .foregroundStyle(theme.colors.textPrimary)
                
                // Notes Text Editor
                VStack(alignment: .leading, spacing: theme.spacing.sm) {
                    Text("Please add your consultation notes")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    TextEditor(text: $notes)
                        .font(theme.typography.body)
                        .frame(height: 200)
                        .padding(theme.spacing.sm)
                        .background(theme.colors.surface)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showValidationError ? Color.red : theme.colors.border, lineWidth: 1)
                        )
                    
                    // Character count
                    Text("\(notes.count) characters")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    
                    if showValidationError {
                        Text("Notes are required to end the call")
                            .font(theme.typography.caption)
                            .foregroundStyle(.red)
                    }
                    
                    if let apiError {
                        Text(apiError)
                            .font(theme.typography.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Buttons
                VStack(spacing: theme.spacing.md) {
                    // End Call button
                    Button(action: {
                        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else {
                            showValidationError = true
                            return
                        }
                        showValidationError = false
                        apiError = nil
                        isLoading = true
                        Task {
                            let success = await onEndCall(notes)
                            isLoading = false
                            if !success {
                                apiError = "Failed to end consultation. Please try again."
                            }
                            // On success the caller sets isPresented = false and pops
                        }
                    }) {
                        ZStack {
                            Text("End Call")
                                .font(theme.typography.medium16)
                                .foregroundStyle(.white)
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background((notes.isEmpty || isLoading) ? theme.colors.textSecondary : Color.red)
                        .cornerRadius(12)
                    }
                    .disabled(notes.isEmpty || isLoading)
                    
                    // Cancel — dismisses the popup, call continues in the background
                    Button(action: {
                        isPresented = false
                    }) {
                        Text("Cancel")
                            .font(theme.typography.medium16)
                            .foregroundStyle(theme.colors.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(theme.colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.colors.primary, lineWidth: 2)
                            )
                    }
                    .disabled(isLoading)
                }
            }
            .padding(theme.spacing.lg)
            .background(theme.colors.background)
            .cornerRadius(20)
            .padding(theme.spacing.lg)
        }
    }
}

#Preview {
    DoctorNotesFormView(
        notes: .constant(""),
        isPresented: .constant(true),
        onEndCall: { _ in return true }
    )
    .appTheme(AppTheme.default)
}
