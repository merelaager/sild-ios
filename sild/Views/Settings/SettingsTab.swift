//
//  SettingsTab.swift
//  sild
//

import SwiftUI

struct SettingsTab: View {
    @Environment(AuthService.self) private var auth
    @State private var didClearCache = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading) {
                        Text(auth.currentUser?.name ?? "[nimi]")
                        Text(auth.currentUser?.email ?? "[meil]")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Link(
                        destination: URL(
                            string:
                                "https://sild.merelaager.ee/privaatsustingimused"
                        )!
                    ) {
                        HStack(spacing: 4) {
                            Text("Privaatsustingimused")
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                    }
                }

                Section("Laager") {
                    LabeledContent("Vahetus") {
                        if let shift = auth.currentUser?.currentShift {
                            Text("\(shift)")
                        } else {
                            Text("[vahetus]")
                        }
                    }
                }

                Section {
                    Button(didClearCache ? "Vahemälu tühjendatud" : "Tühjenda vahemälu") {
                        DiskCache.clearAll(excluding: [AuthService.userCacheKey])
                        didClearCache = true
                    }
                    .disabled(didClearCache)
                } header: {
                    Text("Rakendus")
                } footer: {
                    Text("Eemalda seadmesse salvestatud andmed, näiteks laste ja meeskondade info. Aitab andmekonflikti või aegunud andmete korral.")
                }

                Section {
                    Button("Logi välja", role: .destructive) {
                        auth.logout()
                    }
                }
            }
            .navigationTitle("Sätted")
            .onAppear { didClearCache = false }
        }
    }
}

#Preview {
    SettingsTab().environment(AuthService())
}
