//
//  TeamsTab.swift
//  sild
//

import SwiftUI

struct TeamsTab: View {
    let records: ShiftRecordsStore
    let teams: TeamsStore
    let shiftNr: Int

    private var allRecords: [ShiftRecord] { records.records }

    private var ghostRecords: [ShiftRecord] {
        allRecords.filter { $0.teamId == nil }.sortedByName()
    }

    private func members(of teamId: Int) -> [ShiftRecord] {
        allRecords.filter { $0.teamId == teamId }.sortedByName()
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Meeskonnad")
        }
    }

    @ViewBuilder
    private var content: some View {
        if records.isLoading && allRecords.isEmpty {
            ProgressView()
        } else if let error = records.errorMessage, allRecords.isEmpty {
            ContentUnavailableView(
                "Couldn't load records",
                systemImage: "exclamationmark.triangle",
                description: Text(error)
            )
        } else if allRecords.isEmpty {
            ContentUnavailableView(
                "No records",
                systemImage: "tray",
                description: Text("There are no records for this shift.")
            )
        } else if !teams.teams.isEmpty {
            teamsList(teams: teams.teams)
        } else if let teamsError = teams.errorMessage {
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
        async let r: Void = records.load(shiftNr: shiftNr)
        async let t: Void = teams.load(shiftNr: shiftNr)
        _ = await r
        _ = await t
    }
}
