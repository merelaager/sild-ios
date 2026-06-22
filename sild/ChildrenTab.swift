//
//  ChildrenTab.swift
//  sild
//

import SwiftUI

struct ChildrenTab: View {
    let records: [ShiftRecord]
    let isLoading: Bool
    let errorMessage: String?
    let reload: () async -> Void
    let setPresence: (Int, Bool) async -> Void
    let setTent: (Int, Int?) async -> Void
    let setTeam: (Int, Int?, String?) async -> Void

    @State private var searchText: String = ""

    private var sortedRecords: [ShiftRecord] {
        records.sorted {
            $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending
        }
    }

    private var filteredRecords: [ShiftRecord] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sortedRecords }
        return sortedRecords.filter {
            $0.childName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        NavigationStack {
            Group {
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
                } else if filteredRecords.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredRecords) { record in
                        NavigationLink(value: record.id) {
                            RecordRow(
                                record: record,
                                showsTent: true,
                                showsTeam: true
                            )
                        }
                    }
                    .refreshable { await reload() }
                }
            }
            .navigationTitle("Lapsed")
            .searchable(text: $searchText, prompt: "Otsi last")
            .navigationDestination(for: Int.self) { recordId in
                if let record = records.first(where: { $0.id == recordId }) {
                    ChildDetailView(
                        record: record,
                        setPresence: { value in await setPresence(recordId, value) },
                        setTent: { value in await setTent(recordId, value) },
                        setTeam: { teamId, teamName in await setTeam(recordId, teamId, teamName) }
                    )
                }
            }
        }
    }
}
