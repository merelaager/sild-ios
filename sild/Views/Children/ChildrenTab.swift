//
//  ChildrenTab.swift
//  sild
//

import SwiftUI

struct ChildrenTab: View {
    let store: ShiftRecordsStore
    @Binding var path: NavigationPath

    @State private var searchText: String = ""

    private var filteredRecords: [ShiftRecord] {
        let sorted = store.records.sortedByName()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.childName.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if store.isLoading && store.records.isEmpty {
                    ProgressView()
                } else if let error = store.errorMessage, store.records.isEmpty {
                    ContentUnavailableView(
                        "Couldn't load records",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else if store.records.isEmpty {
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
                            RecordRow(record: record, showsTent: true, showsTeam: true)
                        }
                    }
                }
            }
            .navigationTitle("Lapsed")
            .searchable(text: $searchText, prompt: "Otsi last")
            .navigationDestination(for: Int.self) { recordId in
                if let record = store.records.first(where: { $0.id == recordId }) {
                    ChildDetailView(record: record, store: store)
                }
            }
        }
    }
}
