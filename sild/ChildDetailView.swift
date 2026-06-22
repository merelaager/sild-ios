//
//  ChildDetailView.swift
//  sild
//

import SwiftUI

struct ChildDetailView: View {
    let record: ShiftRecord
    let setPresence: (Bool) async -> Void
    let setTent: (Int?) async -> Void
    let setTeam: (Int?, String?) async -> Void

    @State private var teams: [Team] = []
    @State private var teamsLoadError: String?
    @State private var registration: Registration?
    @State private var registrationLoadError: String?

    var body: some View {
        Form {
            Section("Kohalolek") {
                Toggle("Kohal", isOn: presenceBinding)
                    .tint(.accentColor)
            }

            Section("Telk") {
                Picker("Telk", selection: tentBinding) {
                    Text("Puudub").tag(Int?.none)
                    ForEach(1...10, id: \.self) { number in
                        Text("Telk \(number)").tag(Int?.some(number))
                    }
                }
            }

            Section("Meeskond") {
                Picker("Meeskond", selection: teamBinding) {
                    Text("Puudub").tag(Int?.none)
                    ForEach(teams) { team in
                        Text(team.name).tag(Int?.some(team.id))
                    }
                }
                .disabled(teams.isEmpty)

                if let teamsLoadError {
                    Text(teamsLoadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Andmed") {
                LabeledContent("Vanus", value: "\(record.ageAtCamp)")

                if let sex = sexLabel {
                    LabeledContent("Sugu", value: sex)
                }

                if let registration {
                    LabeledContent("Uus", value: registration.isOld ? "Ei" : "Jah")
                    if let name = registration.contactName, !name.isEmpty {
                        LabeledContent("Lapsevanem", value: name)
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

                if let registrationLoadError {
                    Text(registrationLoadError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(record.childName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            async let teamsLoad: Void = loadTeams()
            async let registrationLoad: Void = loadRegistration()
            _ = await teamsLoad
            _ = await registrationLoad
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

    private var sexLabel: String? {
        switch registration?.child.sex {
        case "M": return "Poiss"
        case "F": return "Tüdruk"
        default: return nil
        }
    }

    private func loadTeams() async {
        teamsLoadError = nil
        do {
            teams = try await TeamsAPI.fetch(shiftNr: record.shiftNr)
        } catch {
            teamsLoadError = error.localizedDescription
        }
    }

    private func loadRegistration() async {
        registrationLoadError = nil
        do {
            let all = try await RegistrationsAPI.fetch(shiftNr: record.shiftNr)
            registration = all.first { $0.childId == record.childId }
        } catch {
            registrationLoadError = error.localizedDescription
        }
    }

    private var presenceBinding: Binding<Bool> {
        Binding(
            get: { record.isPresent },
            set: { newValue in Task { await setPresence(newValue) } }
        )
    }

    private var tentBinding: Binding<Int?> {
        Binding(
            get: { record.tentNr },
            set: { newValue in Task { await setTent(newValue) } }
        )
    }

    private var teamBinding: Binding<Int?> {
        Binding(
            get: { record.teamId },
            set: { newValue in
                let name = newValue.flatMap { id in teams.first(where: { $0.id == id })?.name }
                Task { await setTeam(newValue, name) }
            }
        )
    }
}
