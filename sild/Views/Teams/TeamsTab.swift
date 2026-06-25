//
//  TeamsTab.swift
//  sild
//

import SwiftUI

struct TeamsTab: View {
    let store: ShiftRecordsStore
    let shiftNr: Int

    @State private var teams: [Team]?
    @State private var teamsError: String?

    private var records: [ShiftRecord] { store.records }

    private var ghostRecords: [ShiftRecord] {
        records.filter { $0.teamId == nil }.sortedByName()
    }

    private func members(of teamId: Int) -> [ShiftRecord] {
        records.filter { $0.teamId == teamId }.sortedByName()
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
        if store.isLoading && records.isEmpty {
            ProgressView()
        } else if let error = store.errorMessage, records.isEmpty {
            ContentUnavailableView(
                "Couldn't load records",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
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
                        let teamMembers = members(of: team.id)
                        if teamMembers.isEmpty {
                            Text("Liikmed puuduvad").foregroundStyle(.tertiary)
                        } else {
                            ForEach(teamMembers) { record in
                                RecordRow(record: record, showsTent: true)
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
            .refreshable { await reloadAll() }
        }
    }

    private func indexRow(title: String, targetId: String, proxy: ScrollViewProxy) -> some View {
        Button {
            withAnimation {
                proxy.scrollTo(targetId, anchor: .top)
            }
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func reloadAll() async {
        async let records: Void = store.load(shiftNr: shiftNr)
        async let teamsResult: Void = loadTeams()
        _ = await records
        _ = await teamsResult
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
