//
//  TentsTab.swift
//  sild
//

import SwiftUI

struct TentsTab: View {
    let store: ShiftRecordsStore
    let scoring: TentScoringCoordinator
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
                        store: store,
                        scoring: scoring,
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
                            TentCard(title: "\(number). telk", names: firstNames(forTent: number))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .refreshable { await store.load(shiftNr: shiftNr) }
        }
    }

    private func firstNames(forTent number: Int) -> [String] {
        records.filter { $0.tentNr == number }
            .sortedByName()
            .compactMap { $0.childName.split(separator: " ").first.map(String.init) }
    }
}

private struct TentCard: View {
    let title: String
    let names: [String]

    var body: some View {
        VStack(spacing: 6) {
            Text(title).font(.headline)
            VStack(spacing: 2) {
                Text(firstRow)
                Text(secondRow)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 80)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var firstRow: String {
        names.isEmpty ? "Tühi" : names.prefix(2).joined(separator: ", ")
    }

    private var secondRow: String {
        let middle = names.dropFirst(2).prefix(2).joined(separator: ", ")
        if names.count > 4 {
            return middle.isEmpty ? "…" : "\(middle), …"
        }
        return middle
    }
}
