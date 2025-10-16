//
//  DropdownField.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 14/10/25.
//


import SwiftUI

/// Generic dropdown field that shows a button and presents GenericSelectionListView in a sheet.
/// T must be Hashable & CustomStringConvertible so the GenericSelectionListView can display it.
struct DropdownField<T: Hashable & CustomStringConvertible>: View {
    @Environment(\.appTheme) private var theme

    /// The currently selected value (optional) - for single selection
    @Binding var selectedValue: T?
    
    /// The currently selected values - for multi selection
    @Binding var selectedValues: [T]

    /// List of items to choose from
    let items: [T]

    /// Title shown on the button when an item is selected (if `showTitle` is true, else title above field)
    let placeholder: String
    let title: String?
    let allowsSearch: Bool
    let showsChevron: Bool
    let allowsMultiSelection: Bool

    /// Optional inline error text. If present, border will be highlighted.
    var errorText: String?

    @State private var showPicker = false
    @State private var tempSelection: T? = nil
    @State private var tempMultiSelection: [T] = []

    // Single selection initializer
    init(
        selectedValue: Binding<T?>,
        items: [T],
        placeholder: String = "Select",
        title: String? = nil,
        allowsSearch: Bool = true,
        showsChevron: Bool = true,
        errorText: String? = nil
    ) {
        self._selectedValue = selectedValue
        self._selectedValues = .constant([])
        self.items = items
        self.placeholder = placeholder
        self.title = title
        self.allowsSearch = allowsSearch
        self.showsChevron = showsChevron
        self.allowsMultiSelection = false
        self.errorText = errorText
    }
    
    // Multi selection initializer
    init(
        selectedValues: Binding<[T]>,
        items: [T],
        placeholder: String = "Select",
        title: String? = nil,
        allowsSearch: Bool = true,
        showsChevron: Bool = true,
        errorText: String? = nil
    ) {
        self._selectedValue = .constant(nil)
        self._selectedValues = selectedValues
        self.items = items
        self.placeholder = placeholder
        self.title = title
        self.allowsSearch = allowsSearch
        self.showsChevron = showsChevron
        self.allowsMultiSelection = true
        self.errorText = errorText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let title = title {
                Text(title)
                    .font(theme.typography.callout)
                    .foregroundStyle(theme.colors.textPrimary)
            }

            Button(action: {
                // Initialize temp selections with current values
                if allowsMultiSelection {
                    tempMultiSelection = selectedValues
                } else {
                    tempSelection = selectedValue
                }
                showPicker.toggle()
            }) {
                HStack {
                    Text(displayText)
                        .font(theme.typography.callout)
                        .foregroundStyle(hasSelection ? theme.colors.textPrimary : theme.colors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    if showsChevron {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(theme.colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.cornerRadius)
                        .stroke(errorText != nil ? Color.red : theme.colors.border, lineWidth: errorText != nil ? 1.5 : 1)
                )
                .cornerRadius(theme.cornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showPicker) {
                if allowsMultiSelection {
                    GenericSelectionListView<T>(
                        selectedValues: $tempMultiSelection,
                        title: title ?? placeholder,
                        items: items,
                        allowsSearch: allowsSearch,
                        allowsMultiSelection: true
                    )
                    .onDisappear {
                        // Write multi-selection back when sheet dismisses
                        selectedValues = tempMultiSelection
                    }
                } else {
                    GenericSelectionListView<T>(
                        selectedValue: $tempSelection,
                        title: title ?? placeholder,
                        items: items,
                        allowsSearch: allowsSearch
                    )
                    .onDisappear {
                        // Write selection back when the sheet dismisses
                        if let sel = tempSelection {
                            selectedValue = sel
                        }
                    }
                }
            }

            if let err = errorText {
                Text(err)
                    .font(theme.typography.caption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayText: String {
        if allowsMultiSelection {
            if selectedValues.isEmpty {
                return placeholder
            } else if selectedValues.count == 1 {
                return selectedValues.first?.description ?? placeholder
            } else {
                return "\(selectedValues.count) items selected"
            }
        } else {
            return selectedValue?.description ?? placeholder
        }
    }
    
    private var hasSelection: Bool {
        if allowsMultiSelection {
            return !selectedValues.isEmpty
        } else {
            return selectedValue != nil
        }
    }
}

// Convenience non-generic alias for String specializations
typealias StringDropdownField = DropdownField<String>

// MARK: - Preview
#if DEBUG
struct DropdownField_Previews: PreviewProvider {
    struct PreviewHost: View {
        @State var selected: String? = nil
        @State var selectedModel: SampleItem? = nil
        @State var multiSelected: [String] = []
        @State var multiSelectedModels: [SampleItem] = []

        var body: some View {
            VStack(spacing: 16) {
                // Single selection example
                StringDropdownField(
                    selectedValue: $selected,
                    items: ["General Physician", "Cardiology", "Dermatology", "Pediatrics"],
                    placeholder: "Select Specialization",
                    title: "Specialization (Single)",
                    allowsSearch: true,
                    errorText: selected == nil ? "Please select a specialization" : nil
                )

                // Multi selection example
                StringDropdownField(
                    selectedValues: $multiSelected,
                    items: ["Consultation", "Surgery", "Emergency", "Routine Checkup", "Follow-up"],
                    placeholder: "Select Services",
                    title: "Services (Multi-Selection)",
                    allowsSearch: true,
                    errorText: multiSelected.isEmpty ? "Please select at least one service" : nil
                )

                // Single selection with custom model
                DropdownField(
                    selectedValue: $selectedModel,
                    items: SampleItem.sampleData(),
                    placeholder: "Select an item",
                    title: "Model Dropdown (Single)",
                    allowsSearch: true,
                    errorText: nil
                )

                // Multi selection with custom model
                DropdownField(
                    selectedValues: $multiSelectedModels,
                    items: SampleItem.sampleData(),
                    placeholder: "Select items",
                    title: "Model Dropdown (Multi)",
                    allowsSearch: true,
                    errorText: nil
                )
            }
            .padding()
            .appTheme(AppTheme.default)
        }
    }

    // sample model to demonstrate generic behavior
    struct SampleItem: Hashable, CustomStringConvertible {
        let id: Int
        let name: String
        var description: String { name }

        static func sampleData() -> [SampleItem] {
            [SampleItem(id: 1, name: "Alpha"), SampleItem(id: 2, name: "Beta"), SampleItem(id: 3, name: "Gamma")]
        }
    }

    static var previews: some View {
        PreviewHost()
    }
}
#endif
