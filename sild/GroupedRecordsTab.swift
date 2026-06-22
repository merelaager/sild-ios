//
//  GroupedRecordsTab.swift
//  sild
//

import SwiftUI

struct GroupedRecordsTab: View {
    let title: String
    let records: [ShiftRecord]
    let isLoading: Bool
    let errorMessage: String?
    let sections: [RecordSection]
    let reload: () async -> Void

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
                } else {
                    List {
                        ForEach(sections) { section in
                            Section(section.title) {
                                ForEach(section.records) { record in
                                    RecordRow(record: record)
                                }
                            }
                        }
                    }
                    .refreshable { await reload() }
                }
            }
            .navigationTitle(title)
        }
    }
}


