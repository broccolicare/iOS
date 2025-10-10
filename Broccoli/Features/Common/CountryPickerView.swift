//
//  CountryPickerView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 10/10/25.
//
import SwiftUI

struct CountryPickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedCode: String

    // small demo list
    let countries = ["+1", "+44", "+91", "+353", "+61"]

    var body: some View {
        NavigationView {
            List(countries, id: \.self) { c in
                Button(action: {
                    selectedCode = c
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text(c)
                }
            }
            .navigationTitle("Select Country")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
    }
}
