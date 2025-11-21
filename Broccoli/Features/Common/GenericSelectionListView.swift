//
//  GenericSelectionListView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 13/10/25.
//

import SwiftUI

/// A generic reusable selection list for choosing a value from a list of options.
/// Can be used for country picker, specialization picker, gender, etc.
/// Supports both single and multi-selection modes.
struct GenericSelectionListView<T: Hashable & CustomStringConvertible>: View {
    @Environment(\.presentationMode) private var presentationMode
    
    // Single selection binding
    @Binding var selectedValue: T?
    
    // Multi selection binding
    @Binding var selectedValues: [T]

    var title: String
    var items: [T]
    var allowsSearch: Bool = true
    var allowsMultiSelection: Bool = false

    // search
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    
    // Single selection initializer
    init(
        selectedValue: Binding<T?>,
        title: String,
        items: [T],
        allowsSearch: Bool = true
    ) {
        self._selectedValue = selectedValue
        self._selectedValues = .constant([])
        self.title = title
        self.items = items
        self.allowsSearch = allowsSearch
        self.allowsMultiSelection = false
    }
    
    // Multi selection initializer
    init(
        selectedValues: Binding<[T]>,
        title: String,
        items: [T],
        allowsSearch: Bool = true,
        allowsMultiSelection: Bool = true
    ) {
        self._selectedValue = .constant(nil)
        self._selectedValues = selectedValues
        self.title = title
        self.items = items
        self.allowsSearch = allowsSearch
        self.allowsMultiSelection = allowsMultiSelection
    }

    private var filteredItems: [T] {
        guard allowsSearch, !searchText.isEmpty else { return items }
        return items.filter { $0.description.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredItems, id: \.self) { item in
                    Button(action: {
                        if allowsMultiSelection {
                            toggleMultiSelection(for: item)
                        } else {
                            selectedValue = item
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        HStack {
                            Text(item.description)
                                .foregroundColor(.primary)
                            Spacer()
                            
                            if allowsMultiSelection {
                                // Multi-selection checkmark
                                if selectedValues.contains(item) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray)
                                }
                            } else {
                                // Single selection checkmark
                                if selectedValue == item {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .if(allowsSearch) { view in
                view.searchable(text: $searchText, prompt: "Search")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                if allowsMultiSelection {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func toggleMultiSelection(for item: T) {
        if selectedValues.contains(item) {
            selectedValues.removeAll { $0 == item }
        } else {
            selectedValues.append(item)
        }
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
