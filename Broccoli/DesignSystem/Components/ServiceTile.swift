//
//  ServiceTile.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 02/11/25.
//
import SwiftUI

struct ServiceTile: View {
    @Environment(\.appTheme) private var theme
    let item: ServiceItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SmallActionTile(
                title: item.title,
                backgroundImage: item.backgroundImage
            )
            .frame(height: 140)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
