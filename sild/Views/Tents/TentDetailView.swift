//
//  TentDetailView.swift
//  sild
//

import SwiftUI

struct TentDetailView: View {
    let tentNumber: Int
    let shiftNr: Int
    let records: [ShiftRecord]
    @Binding var path: NavigationPath

    @State private var scores: [TentScore] = []
    @State private var isLoadingScores: Bool = false
    @State private var scoresError: String?
    @State private var isAddGradeSheetPresented: Bool = false

    private var hasPrevious: Bool { tentNumber > 1 }
    private var hasNext: Bool { tentNumber < 10 }

    private var sortedScores: [TentScore] {
        scores.sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            Section("Lapsed") {
                if records.isEmpty {
                    Text("Telk on tühi").foregroundStyle(.secondary)
                } else {
                    ForEach(records) { record in
                        RecordRow(record: record, showsTeam: true)
                    }
                }
            }

            Section("Hinded") {
                if isLoadingScores && scores.isEmpty {
                    HStack { Spacer(); ProgressView(); Spacer() }
                } else if let scoresError, scores.isEmpty {
                    Text(scoresError).foregroundStyle(.red)
                } else if scores.isEmpty {
                    Text("Hindeid pole").foregroundStyle(.secondary)
                } else {
                    ForEach(sortedScores) { score in
                        ScoreRow(score: score)
                    }
                }
            }
        }
        .navigationTitle("\(tentNumber). telk")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { path = NavigationPath() } label: {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel("Tagasi")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            addGradeButton
                .padding(.trailing, 32)
                .padding(.bottom, 20)
        }
        .task { await loadScores() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 40).onEnded(handleSwipe)
        )
        .sheet(isPresented: $isAddGradeSheetPresented) {
            AddScoreSheet(tentNumber: tentNumber) { score in
                try await TentsAPI.setScore(shiftNr: shiftNr, tentNr: tentNumber, score: score)
                await loadScores()
            }
        }
        .accessibilityAction(named: Text("Eelmine telk")) {
            if hasPrevious { path.append(tentNumber - 1) }
        }
        .accessibilityAction(named: Text("Järgmine telk")) {
            if hasNext { path.append(tentNumber + 1) }
        }
    }

    @ViewBuilder
    private var addGradeButton: some View {
        let action = { isAddGradeSheetPresented = true }
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: "square.and.pencil")
                    .font(.title2)
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Lisa hinne")
        } else {
            Button(action: action) {
                Image(systemName: "square.and.pencil").font(.title2)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Lisa hinne")
        }
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) > abs(dy) * 1.5, abs(dx) > 80 else { return }
        let target: Int?
        if dx > 0, hasPrevious {
            target = tentNumber - 1
        } else if dx < 0, hasNext {
            target = tentNumber + 1
        } else {
            target = nil
        }
        guard let target else { return }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            path.append(target)
        }
    }

    private func loadScores() async {
        isLoadingScores = true
        scoresError = nil
        defer { isLoadingScores = false }
        do {
            scores = try await TentsAPI.fetchScores(shiftNr: shiftNr, tentNr: tentNumber)
        } catch {
            scoresError = error.localizedDescription
        }
    }
}

private struct ScoreRow: View {
    let score: TentScore

    private static let estonian = Locale(identifier: "et_EE")

    var body: some View {
        HStack {
            Text(score.score, format: .number)
                .font(.title3)
                .fontWeight(.semibold)
            Spacer()
            Text(timestamp)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var timestamp: String {
        guard let date = score.createdAtDate else { return score.createdAt }
        return date.formatted(.relative(presentation: .named).locale(Self.estonian))
    }
}

private struct AddScoreSheet: View {
    let tentNumber: Int
    let submit: (Int) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scoreText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack {
                Text("Sisesta hinne").font(.title3)
                TextField("0", text: $scoreText)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 80, alignment: .center)
                    .font(.largeTitle)
                    .onChange(of: scoreText) {
                        scoreText = String(scoreText.prefix(2))
                    }
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("\(tentNumber). telk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tühista") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvesta") { save() }
                        .disabled(isSubmitting || Int(scoreText) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        guard let score = Int(scoreText) else { return }
        Task {
            isSubmitting = true
            errorMessage = nil
            defer { isSubmitting = false }
            do {
                try await submit(score)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
