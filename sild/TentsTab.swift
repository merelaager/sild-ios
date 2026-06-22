//
//  TentsTab.swift
//  sild
//

import SwiftUI

struct TentsTab: View {
    let records: [ShiftRecord]
    let isLoading: Bool
    let errorMessage: String?
    let reload: () async -> Void

    private let tentRange = 1...10
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Telgid")
                .navigationDestination(for: Int.self) { number in
                    TentDetailView(tentNumber: number, records: kids(forTent: number))
                }
        }
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
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(tentRange), id: \.self) { number in
                        NavigationLink(value: number) {
                            TentCard(title: "Telk \(number)", count: count(forTent: number))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .refreshable { await reload() }
        }
    }

    private func count(forTent number: Int) -> Int {
        records.lazy.filter { $0.tentNr == number }.count
    }

    private func kids(forTent number: Int) -> [ShiftRecord] {
        records
            .filter { $0.tentNr == number }
            .sorted { $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending }
    }
}

private struct TentCard: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.headline)
            Text(countLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var countLabel: String {
        count == 1 ? "1 laps" : "\(count) last"
    }
}

private struct TentDetailView: View {
    let tentNumber: Int
    let records: [ShiftRecord]

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "Telk on tühi",
                    systemImage: "tent",
                    description: Text("Selles telgis pole ühtegi last.")
                )
            } else {
                List(records) { record in
                    RecordRow(record: record)
                }
            }
        }
        .navigationTitle("Telk \(tentNumber)")
    }
}
