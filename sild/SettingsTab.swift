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
                    VStack(alignment: .leading) {
                        Text(
                            auth.currentUser?.name ?? "[nimi]"
                        )
                        Text(
                            auth.currentUser?.email ?? "[meil]"
                        )
                        .font(
                            .footnote
                        ).foregroundColor(.secondary)
                    }
                }

                Section("Laager") {
                    LabeledContent("Vahetus") {
                        if let currentUser = auth.currentUser {
                            Text("\(currentUser.currentShift! as Int)")
                        } else {
                            Text("[vahetus]")
                        }
                    }
                }

                Section {
                    Button("Logi välja", role: .destructive) {
                        auth.logout()
                    }
                }
            }
            .navigationTitle("Sätted")
        }
    }
}

#Preview {
    let auth = AuthService()
    return SettingsTab().environment(auth)
}
