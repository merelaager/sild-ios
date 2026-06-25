//
//  ChildDetailView.swift
//  sild
//

import SwiftUI

struct ChildDetailView: View {
    let record: ShiftRecord
    let store: ShiftRecordsStore

    @State private var teams: [Team] = []
    @State private var registration: Registration?
    @State private var loadError: String?

    var body: some View {
        Form {
            Section("Laager") {
                Picker("Telk", selection: tentBinding) {
                    Text("Määramata").tag(Int?.none)
                    ForEach(1...10, id: \.self) { number in
                        Text("\(number). telk").tag(Int?.some(number))
                    }
                }

                Picker("Meeskond", selection: teamBinding) {
                    Text("Määramata").tag(Int?.none)
                    ForEach(teams) { team in
                        Text(team.name).tag(Int?.some(team.id))
                    }
                }
                .disabled(teams.isEmpty)

                Toggle("Kohal", isOn: presenceBinding)
                    .tint(.accentColor)
            }

            Section("Üldandmed") {
                LabeledContent("Vanus", value: "\(record.ageAtCamp)a")
                if let sex = sexLabel {
                    LabeledContent("Sugu", value: sex)
                }
                if let registration {
                    LabeledContent("Uus", value: registration.isOld ? "Ei" : "Jah")
                }
            }

            if let registration {
                Section("Kontaktandmed") {
                    if let name = registration.contactName, !name.isEmpty {
                        LabeledContent("Nimi", value: name)
                    }
                    if let phone = registration.contactNumber, !phone.isEmpty {
                        LabeledContent("Telefon") {
                            if let url = telURL(for: phone) {
                                Link(phone, destination: url)
                            } else {
                                Text(phone).foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let email = registration.contactEmail, !email.isEmpty {
                        LabeledContent("E-post") {
                            if let url = mailtoURL(for: email) {
                                Link(email, destination: url)
                            } else {
                                Text(email).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let loadError {
                Text(loadError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle(record.childName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private var sexLabel: String? {
        switch registration?.child.sex {
        case "M": return "Poiss"
        case "F": return "Tüdruk"
        default: return nil
        }
    }

    private func load() async {
        loadError = nil
        do {
            async let teamsResult = TeamsAPI.fetch(shiftNr: record.shiftNr)
            async let registrationsResult = RegistrationsAPI.fetch(shiftNr: record.shiftNr)
            teams = try await teamsResult
            registration = try await registrationsResult.first { $0.childId == record.childId }
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func telURL(for phone: String) -> URL? {
        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
        guard !cleaned.isEmpty else { return nil }
        return URL(string: "tel:\(cleaned)")
    }

    private func mailtoURL(for email: String) -> URL? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        return URL(string: "mailto:\(encoded)")
    }

    private var presenceBinding: Binding<Bool> {
        Binding(
            get: { record.isPresent },
            set: { newValue in Task { await store.setPresence(recordId: record.id, isPresent: newValue) } }
        )
    }

    private var tentBinding: Binding<Int?> {
        Binding(
            get: { record.tentNr },
            set: { newValue in Task { await store.setTent(recordId: record.id, tentNr: newValue) } }
        )
    }

    private var teamBinding: Binding<Int?> {
        Binding(
            get: { record.teamId },
            set: { newValue in
                let name = newValue.flatMap { id in teams.first(where: { $0.id == id })?.name }
                Task { await store.setTeam(recordId: record.id, teamId: newValue, teamName: name) }
            }
        )
    }
}
