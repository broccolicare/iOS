//
//  PatientRootTabView.swift
//  Broccoli
//
//  Created by Gaurav Jaiswal on 22/10/25.
//
import SwiftUI

struct PatientRootTabView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        MainTabContainer(selected: $selectedTab) { tab in
            switch tab {
            case .home:
                PatientHomeView()
            case .prescription:
                PrescriptionView()
            case .packages:
                PackagesView()
            case .profile:
                ProfileView()
            }
        }
    }
}
