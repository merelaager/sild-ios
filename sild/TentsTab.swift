//
//  TentsTab.swift
//  sild
//

import SwiftUI

struct TentsTab: View {
    @Binding var path: NavigationPath
    let records: [ShiftRecord]
    let isLoading: Bool
    let errorMessage: String?
    let reload: () async -> Void

    private let tentRange = 1...10
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("Telgid")
                .navigationDestination(for: Int.self) { number in
                    TentDetailView(tentNumber: number, records: kids(forTent: number), path: $path)
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
    @Binding var path: NavigationPath

    private var hasPrevious: Bool { tentNumber > 1 }
    private var hasNext: Bool { tentNumber < 10 }

    private func navigate(to tent: Int) {
        path = NavigationPath([tent])
    }

    var body: some View {
        VStack(spacing: 0) {
            if records.isEmpty {
                ContentUnavailableView(
                    "Telk on tühi",
                    systemImage: "tent",
                    description: Text("Selles telgis pole ühtegi last.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(records) { record in
                    RecordRow(record: record, showsTeam: true)
                }
            }

            navigationButtons
        }
        .navigationTitle("Telk \(tentNumber)")
    }

    private var navigationButtons: some View {
        HStack {
            if hasPrevious {
                Button {
                    navigate(to: tentNumber - 1)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Telk \(tentNumber - 1)")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            if hasNext {
                Button {
                    navigate(to: tentNumber + 1)
                } label: {
                    HStack(spacing: 4) {
                        Text("Telk \(tentNumber + 1)")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}
private let previewTentRecords: [ShiftRecord] = [
    ShiftRecord(id: 1, childId: 101, childName: "Sammalhabe",
                teamId: 1, teamName: "Punased", tentNr: 2,
                isPresent: true, ageAtCamp: 14, year: 2026, shiftNr: 3),
    ShiftRecord(id: 2, childId: 102, childName: "Muhv",
                teamId: 2, teamName: "Sinised", tentNr: 2,
                isPresent: false, ageAtCamp: 12, year: 2026, shiftNr: 3),
    ShiftRecord(id: 3, childId: 103, childName: "Kingpool",
                teamId: nil, teamName: nil, tentNr: 2,
                isPresent: true, ageAtCamp: 13, year: 2026, shiftNr: 3),
]

private struct TentDetailPreviewHost: View {
    let initialTent: Int
    let records: [ShiftRecord]
    @State private var path: NavigationPath

    init(tent: Int, records: [ShiftRecord]) {
        initialTent = tent
        self.records = records
        _path = State(initialValue: NavigationPath([tent]))
    }

    var body: some View {
        NavigationStack(path: $path) {
            Text("Telgid")
                .navigationTitle("Telgid")
                .navigationDestination(for: Int.self) { n in
                    TentDetailView(
                        tentNumber: n,
                        records: n == initialTent ? records : [],
                        path: $path
                    )
                }
        }
    }
}

#Preview("Telk 2") {
    TentDetailPreviewHost(tent: 2, records: previewTentRecords)
}

#Preview("Tühi telk") {
    TentDetailPreviewHost(tent: 2, records: [])
}

