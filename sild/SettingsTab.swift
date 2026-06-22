//
//  SettingsTab.swift
//  sild
//

import SwiftUI

struct SettingsTab: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive, action: auth.logout) {
                        Label("Logi välja", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Sätted")
        }
    }
}
