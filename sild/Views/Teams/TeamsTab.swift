//
//  TeamsTab.swift
//  sild
//

import SwiftUI

struct TeamsTab: View {
    let records: ShiftRecordsStore
    let teams: TeamsStore
    let shiftNr: Int

    @State private var addingTeam: Team?
    @State private var isEditing: Bool = false
    @State private var selectedRecordIds: Set<Int> = []

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
                .toolbar {
                    if isEditing {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(role: .destructive) {
                                batchRemoveSelection()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .disabled(selectedRecordIds.isEmpty)
                            .accessibilityLabel("Eemalda valitud")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                isEditing.toggle()
                                if !isEditing {
                                    selectedRecordIds.removeAll()
                                }
                            }
                        } label: {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                        }
                        .accessibilityLabel(isEditing ? "Valmis" : "Muuda")
                    }
                }
        }
    }

    private func batchRemoveSelection() {
        let ids = selectedRecordIds
        selectedRecordIds.removeAll()
        Task {
            for id in ids {
                await records.setTeam(recordId: id, teamId: nil, teamName: nil)
            }
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
            List(selection: $selectedRecordIds) {
                Section("Meeskonnad") {
                    ForEach(teams) { team in
                        indexRow(title: team.name, targetId: "team-\(team.id)", proxy: proxy)
                            .selectionDisabled()
                    }
                    if !ghostRecords.isEmpty {
                        indexRow(title: "Meeskonnata", targetId: "team-none", proxy: proxy)
                            .selectionDisabled()
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
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task {
                                                await records.setTeam(
                                                    recordId: record.id,
                                                    teamId: nil,
                                                    teamName: nil
                                                )
                                            }
                                        } label: {
                                            Label("Eemalda", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        if isEditing {
                            Button {
                                addingTeam = team
                            } label: {
                                Label("Lisa laps", systemImage: "plus")
                            }
                            .selectionDisabled()
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
            .sheet(item: $addingTeam) { team in
                AddTeamMemberSheet(team: team, records: records)
            }
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

private struct AddTeamMemberSheet: View {
    let team: Team
    let records: ShiftRecordsStore

    @Environment(\.dismiss) private var dismiss
    @State private var searchText: String = ""

    private var candidates: [ShiftRecord] {
        records.records.filter { $0.teamId == nil }.sortedByName()
    }

    private var filteredCandidates: [ShiftRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return candidates }
        return candidates.filter {
            $0.childName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if candidates.isEmpty {
                    ContentUnavailableView(
                        "Meeskonnata lapsi pole",
                        systemImage: "person.slash"
                    )
                } else if filteredCandidates.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredCandidates) { record in
                        Button {
                            Task {
                                await records.setTeam(
                                    recordId: record.id,
                                    teamId: team.id,
                                    teamName: team.name
                                )
                            }
                        } label: {
                            RecordRow(record: record, showsTent: true)
                        }
                        .buttonStyle(.plain)
                    }
                    .contentMargins(.top, 0, for: .scrollContent)
                }
            }
            .navigationTitle(team.name)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Otsi last")
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    if #available(iOS 26.0, *) {
                        Button(role: .confirm) { dismiss() }
                    } else {
                        Button { dismiss() } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityLabel("Valmis")
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    let shiftNr = 1
    let sampleRecords: [ShiftRecord] = [
        ShiftRecord(id: 1, childId: 11, childName: "Toots",
                    teamId: 100, teamName: "Ankur", tentNr: 3,
                    isPresent: true, ageAtCamp: 10, year: 2026, shiftNr: shiftNr),
        ShiftRecord(id: 2, childId: 12, childName: "Teele",
                    teamId: 100, teamName: "Ankur", tentNr: 4,
                    isPresent: true, ageAtCamp: 11, year: 2026, shiftNr: shiftNr),
        ShiftRecord(id: 3, childId: 13, childName: "Tõnisson",
                    teamId: 200, teamName: "Purjekas", tentNr: 5,
                    isPresent: true, ageAtCamp: 9, year: 2026, shiftNr: shiftNr),
        ShiftRecord(id: 4, childId: 14, childName: "Arno",
                    teamId: nil, teamName: nil, tentNr: 1,
                    isPresent: true, ageAtCamp: 12, year: 2026, shiftNr: shiftNr),
    ]
    let sampleTeams: [Team] = [
        Team(id: 100, shiftNr: shiftNr, name: "Ankur", year: 2026, place: nil, captainId: nil),
        Team(id: 200, shiftNr: shiftNr, name: "Purjekas", year: 2026, place: nil, captainId: nil),
    ]
    return TeamsTab(
        records: ShiftRecordsStore(previewRecords: sampleRecords, shiftNr: shiftNr),
        teams: TeamsStore(previewTeams: sampleTeams, shiftNr: shiftNr),
        shiftNr: shiftNr
    )
}
