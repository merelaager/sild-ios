//
//  HomeView.swift
//  sild
//

import SwiftUI

struct HomeView: View {
    let user: CurrentUser

    @State private var records: [ShiftRecord] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        if let shiftNr = user.currentShift {
            TabView {
                TentsTab(
                    records: records,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    reload: { await load(shiftNr: shiftNr) }
                )
                .tabItem { Label("Telgid", systemImage: "tent.fill") }

                TeamsTab(
                    records: records,
                    shiftNr: shiftNr,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    reload: { await load(shiftNr: shiftNr) }
                )
                .tabItem { Label("Meeskonnad", systemImage: "person.3.fill") }

                ChildrenTab(
                    records: records,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    reload: { await load(shiftNr: shiftNr) },
                    setPresence: { id, value in await setPresence(recordId: id, isPresent: value) },
                    setTent: { id, value in await setTent(recordId: id, tentNr: value) },
                    setTeam: { id, teamId, teamName in await setTeam(recordId: id, teamId: teamId, teamName: teamName) }
                )
                .tabItem { Label("Lapsed", systemImage: "person.2.fill") }

                SettingsTab()
                    .tabItem { Label("Sätted", systemImage: "gearshape.fill") }
            }
            .task(id: shiftNr) { await load(shiftNr: shiftNr) }
        } else {
            ContentUnavailableView(
                "No current shift",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("You're not assigned to a shift right now.")
            )
        }
    }

    private func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            records = try await ShiftRecordsAPI.fetch(shiftNr: shiftNr)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setPresence(recordId: Int, isPresent: Bool) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let original = records[index].isPresent
        guard original != isPresent else { return }
        records[index].isPresent = isPresent
        do {
            try await ShiftRecordsAPI.setPresence(recordId: recordId, isPresent: isPresent)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].isPresent = original
            }
        }
    }

    private func setTent(recordId: Int, tentNr: Int?) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let original = records[index].tentNr
        guard original != tentNr else { return }
        records[index].tentNr = tentNr
        do {
            try await ShiftRecordsAPI.setTent(recordId: recordId, tentNr: tentNr)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].tentNr = original
            }
        }
    }

    private func setTeam(recordId: Int, teamId: Int?, teamName: String?) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let originalId = records[index].teamId
        let originalName = records[index].teamName
        guard originalId != teamId else { return }
        records[index].teamId = teamId
        records[index].teamName = teamName
        do {
            try await ShiftRecordsAPI.setTeam(recordId: recordId, teamId: teamId)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].teamId = originalId
                records[revertIndex].teamName = originalName
            }
        }
    }
}
