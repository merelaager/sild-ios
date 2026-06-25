//
//  TentsTab.swift
//  sild
//

import SwiftUI

struct TentsTab: View {
    let store: ShiftRecordsStore
    let shiftNr: Int
    @Binding var path: NavigationPath

    private let tentRange = 1...10
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    private var records: [ShiftRecord] { store.records }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Telgid")
                .navigationDestination(for: Int.self) { number in
                    TentDetailView(
                        tentNumber: number,
                        shiftNr: shiftNr,
                        records: kids(forTent: number),
                        path: $path
                    )
                }
        }
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
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(tentRange), id: \.self) { number in
                        NavigationLink(value: number) {
                            TentCard(title: "\(number). telk", count: count(forTent: number))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .refreshable { await store.load(shiftNr: shiftNr) }
        }
    }

    private func count(forTent number: Int) -> Int {
        records.lazy.filter { $0.tentNr == number }.count
    }

    private func kids(forTent number: Int) -> [ShiftRecord] {
        records.filter { $0.tentNr == number }.sortedByName()
    }
}

private struct TentCard: View {
    let title: String
    let count: Int

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.headline)
            Text(countLabel)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var countLabel: String {
        count == 1 ? "1 laps" : "\(count) last"
    }
}
