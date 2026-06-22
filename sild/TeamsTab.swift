//
//  TeamsTab.swift
//  sild
//

import SwiftUI

struct TeamsTab: View {
    let records: [ShiftRecord]
    let shiftNr: Int
    let isLoading: Bool
    let errorMessage: String?
    let reload: () async -> Void

    @State private var teams: [Team]?
    @State private var teamsError: String?

    private var ghostRecords: [ShiftRecord] {
        records
            .filter { $0.teamId == nil }
            .sorted { $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending }
    }

    private func kids(inTeam id: Int) -> [ShiftRecord] {
        records
            .filter { $0.teamId == id }
            .sorted { $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Meeskonnad")
        }
        .task(id: shiftNr) { await loadTeams() }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && records.isEmpty {
            ProgressView()
        } else if let errorMessage, records.isEmpty {
            ContentUnavailableView(
                "Couldn't load records",
                systemImage: "exclamationmark.triangle",
                description: Text(errorMessage)
            )
        } else if records.isEmpty {
            ContentUnavailableView(
                "No records",
                systemImage: "tray",
                description: Text("There are no records for this shift.")
            )
        } else if let teams {
            teamsList(teams: teams)
        } else if let teamsError {
            ContentUnavailableView(
                "Couldn't load teams",
                systemImage: "exclamationmark.triangle",
                description: Text(teamsError)
            )
        } else {
            ProgressView()
        }
    }

    private func teamsList(teams: [Team]) -> some View {
        ScrollViewReader { proxy in
            List {
                Section("Meeskonnad") {
                    ForEach(teams) { team in
                        indexRow(title: team.name, targetId: "team-\(team.id)", proxy: proxy)
                    }
                    if !ghostRecords.isEmpty {
                        indexRow(title: "Meeskonnata", targetId: "team-none", proxy: proxy)
                    }
                }

                ForEach(teams) { team in
                    Section(team.name) {
                        let members = kids(inTeam: team.id)
                        if members.isEmpty {
                            Text("Liikmed puuduvad")
                                .foregroundStyle(.tertiary)
                        } else {
                            ForEach(members) { record in
                                RecordRow(record: record)
                            }
                        }
                    }
                    .id("team-\(team.id)")
                }

                if !ghostRecords.isEmpty {
                    Section("Meeskonnata") {
                        ForEach(ghostRecords) { record in
                            RecordRow(record: record)
                        }
                    }
                    .id("team-none")
                }
            }
            .refreshable { await combinedReload() }
        }
    }

    private func indexRow(title: String, targetId: String, proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation {
                proxy.scrollTo(targetId, anchor: .top)
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func combinedReload() async {
        async let recordsReload: Void = reload()
        async let teamsReload: Void = loadTeams()
        _ = await recordsReload
        _ = await teamsReload
    }

    private func loadTeams() async {
        teamsError = nil
        do {
            let fetched = try await TeamsAPI.fetch(shiftNr: shiftNr)
            teams = fetched.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            teamsError = error.localizedDescription
        }
    }
}
