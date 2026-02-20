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
    let onEndCall: (String) -> Void
    let onRejoinCall: () -> Void
    let canRejoin: Bool // True if timer hasn't expired
    
    @State private var showValidationError: Bool = false
    
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
                }
                
                // Buttons
                VStack(spacing: theme.spacing.md) {
                    // End Call button (only enabled if notes not empty)
                    Button(action: {
                        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            showValidationError = true
                        } else {
                            showValidationError = false
                            onEndCall(notes)
                            isPresented = false
                        }
                    }) {
                        Text("End Call")
                            .font(theme.typography.medium16)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(notes.isEmpty ? theme.colors.textSecondary : Color.red)
                            .cornerRadius(12)
                    }
                    .disabled(notes.isEmpty)
                    
                    // Rejoin Call button (only if timer hasn't expired)
                    if canRejoin {
                        Button(action: {
                            isPresented = false
                            onRejoinCall()
                        }) {
                            Text("Rejoin Call")
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
                    }
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
        onEndCall: { _ in },
        onRejoinCall: {},
        canRejoin: true
    )
    .appTheme(AppTheme.default)
}
