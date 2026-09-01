//
//  IntakeSummaryView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 01/09/26.
//

import SwiftUI

struct IntakeSummaryView: View {
    @Environment(\.appTheme) private var theme
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var bookingVM: BookingGlobalViewModel

    let booking: BookingData

    var body: some View {
        ZStack(alignment: .top) {
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

                    Text("Intake Summary")
                        .font(theme.typography.medium24)
                        .foregroundStyle(theme.colors.textPrimary)

                    Spacer()

                    Image("back-icon-white")
                        .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        if bookingVM.isFetchingIntakeSummary {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: theme.colors.primary))
                                    .padding(.top, 80)
                                Spacer()
                            }
                        } else if let errorMessage = bookingVM.intakeSummaryErrorMessage {
                            errorState(message: errorMessage)
                        } else if let data = bookingVM.intakeSummary {
                            summaryContent(for: data)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await bookingVM.fetchIntakeSummary(bookingId: booking.id)
        }
    }

    // MARK: - States

    @ViewBuilder
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(theme.colors.textSecondary)
            Text(message)
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
                .multilineTextAlignment(.center)
            Button(action: {
                Task { await bookingVM.fetchIntakeSummary(bookingId: booking.id) }
            }) {
                Text("Retry")
                    .font(theme.typography.semiBold16)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(theme.colors.primary)
                    .cornerRadius(12)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder
    private func summaryContent(for data: IntakeSummaryData) -> some View {
        statusBadge(for: data.status)

        if data.status == "completed", let summary = data.summary {
            section(title: "Chief Complaint", icon: "stethoscope") {
                Text(summary.chiefComplaint ?? "Not provided")
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineSpacing(4)
            }

            section(title: "History of Present Illness", icon: "clock.arrow.circlepath") {
                Text(summary.historyOfPresentIllness ?? "Not provided")
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineSpacing(4)
            }

            if let pain = summary.pain {
                section(title: "Pain", icon: "bolt.heart") {
                    if pain.present == true {
                        labeledRow("Severity", pain.severity)
                        labeledRow("Location", pain.location)
                        labeledRow("Character", pain.character)
                        labeledRow("Onset", pain.onset)
                    } else {
                        Text("No pain reported")
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }

            section(title: "Medications", icon: "pills") {
                bulletList(summary.medications)
            }

            if let allergies = summary.allergies {
                section(title: "Allergies", icon: "allergens") {
                    Text(allergies.status?.replacingOccurrences(of: "_", with: " ").capitalized ?? "Unknown")
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textPrimary)
                    bulletList(allergies.items)
                }
            }

            section(title: "Relevant History", icon: "doc.text") {
                bulletList(summary.relevantHistory)
            }

            section(title: "Family History", icon: "person.2") {
                bulletList(summary.familyHistory)
            }

            if let lifestyle = summary.lifestyle {
                section(title: "Lifestyle", icon: "heart.text.square") {
                    labeledRow("Smoking", lifestyle.smoking)
                    labeledRow("Alcohol", lifestyle.alcohol)
                    if let notes = lifestyle.notes, !notes.isEmpty {
                        labeledRow("Notes", notes)
                    }
                }
            }

            if let pregnancy = summary.pregnancy, pregnancy != "not_applicable" {
                section(title: "Pregnancy", icon: "figure.and.child.holdinghands") {
                    Text(pregnancy.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(theme.typography.regular14)
                        .foregroundStyle(theme.colors.textPrimary)
                }
            }

            if let flags = summary.flags, !flags.isEmpty {
                section(title: "Flags", icon: "flag") {
                    bulletList(flags)
                }
            }
        } else {
            emptyState(for: data.status)
        }
    }

    @ViewBuilder
    private func emptyState(for status: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(theme.colors.textSecondary)
            Text("Intake summary not yet available")
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.textPrimary)
            Text("Status: \(status.replacingOccurrences(of: "_", with: " ").capitalized)")
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Building Blocks

    @ViewBuilder
    private func statusBadge(for status: String) -> some View {
        HStack {
            Text("Status")
                .font(theme.typography.regular16)
                .foregroundStyle(theme.colors.textPrimary)
            Spacer()
            Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(theme.typography.semiBold16)
                .foregroundStyle(theme.colors.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(theme.colors.primary.opacity(0.1))
                .cornerRadius(8)
        }
    }

    @ViewBuilder
    private func section<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.colors.profileDetailSectionBackground)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(theme.colors.primary)
                }
                Text(title)
                    .font(theme.typography.bold18)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
            }
            content()
        }
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private func labeledRow(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(label)
                    .font(theme.typography.regular12)
                    .foregroundStyle(theme.colors.textSecondary)
                    .frame(width: 90, alignment: .leading)
                Text(value.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(theme.typography.regular14)
                    .foregroundStyle(theme.colors.textPrimary)
            }
        }
    }

    @ViewBuilder
    private func bulletList(_ items: [String]?) -> some View {
        if let items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(theme.colors.textSecondary)
                        Text(item)
                            .font(theme.typography.regular14)
                            .foregroundStyle(theme.colors.textPrimary)
                    }
                }
            }
        } else {
            Text("None reported")
                .font(theme.typography.regular14)
                .foregroundStyle(theme.colors.textSecondary)
        }
    }
}
