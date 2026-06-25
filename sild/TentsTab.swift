//
//  TentsTab.swift
//  sild
//

import SwiftUI

struct TentsTab: View {
    @Binding var path: NavigationPath
    let records: [ShiftRecord]
    let shiftNr: Int
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
                            TentCard(title: "\(number). telk", count: count(forTent: number))
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

struct TentScore: Decodable, Identifiable {
    let scoreId: Int
    let score: Double
    let createdAt: String

    var id: Int { scoreId }

    var createdAtDate: Date? {
        try? Date(createdAt, strategy: .iso8601)
    }
}

private struct TentDetailPayload: Decodable {
    let scores: [TentScore]
}

enum TentsAPI {
    static func fetch(shiftNr: Int, tentNr: Int) async throws -> [TentScore] {
        let url = API.baseURL.appendingPathComponent("api/shifts/\(shiftNr)/tents/\(tentNr)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("[Tents] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Tents] GET transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        print("[Tents] GET status \(http.statusCode) body: \(String(data: data, encoding: .utf8) ?? "<binary>")")

        switch http.statusCode {
        case 200..<300:
            do {
                let envelope = try JSONDecoder().decode(JSendResponse<TentDetailPayload>.self, from: data)
                guard envelope.status == "success", let payload = envelope.data else {
                    throw AuthError.invalidResponse
                }
                return payload.scores
            } catch let error as AuthError {
                throw error
            } catch {
                print("[Tents] GET decoding error: \(error)")
                throw AuthError.decoding(error)
            }
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }

    static func setScore(shiftNr: Int, tentNr: Int, score: Int) async throws {
        let url = API.baseURL.appendingPathComponent("api/shifts/\(shiftNr)/tents/\(tentNr)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = try JSONEncoder().encode(["score": score])

        print("[Tents] POST \(url.absoluteString) score=\(score)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Tents] POST transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        print("[Tents] POST status \(http.statusCode) body: \(String(data: data, encoding: .utf8) ?? "<binary>")")

        switch http.statusCode {
        case 200..<300:
            return
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }
}

private struct ScoreRow: View {
    let score: TentScore

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

    private static let estonian = Locale(identifier: "et_EE")

    private var timestamp: String {
        guard let date = score.createdAtDate else { return score.createdAt }
        return date.formatted(.relative(presentation: .named).locale(Self.estonian))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var countLabel: String {
        count == 1 ? "1 laps" : "\(count) last"
    }
}

private enum ScoreFeedback: Equatable {
    case success(String)
    case error(String)
}

private struct TentDetailView: View {
    let tentNumber: Int
    let shiftNr: Int
    let records: [ShiftRecord]
    @Binding var path: NavigationPath

    @State private var scoreText: String = ""
    @State private var isSubmittingScore: Bool = false
    @State private var scoreFeedback: ScoreFeedback?
    @State private var scores: [TentScore] = []
    @State private var isLoadingScores: Bool = false
    @State private var scoresError: String?
    @State private var isAddGradeSheetPresented: Bool = false

    private var hasPrevious: Bool { tentNumber > 1 }
    private var hasNext: Bool { tentNumber < 10 }

    private func navigate(to tent: Int) {
        path = NavigationPath([tent])
    }

    var body: some View {
        List {
            Section("Lapsed") {
                if records.isEmpty {
                    Text("Telk on tühi")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(records) { record in
                        RecordRow(record: record, showsTeam: true)
                    }
                }
            }

            Section("Hinded") {
                if isLoadingScores && scores.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let scoresError, scores.isEmpty {
                    Text(scoresError)
                        .foregroundStyle(.red)
                } else if scores.isEmpty {
                    Text("Hindeid pole")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedScores) { score in
                        ScoreRow(score: score)
                    }
                }
            }
        }
        .navigationTitle("\(tentNumber). telk")
        .overlay(alignment: .bottomTrailing) {
            addGradeButton
                .padding(.trailing, 20)
                .padding(.bottom, 20)
        }
        .task { await loadScores() }
        .simultaneousGesture(
            DragGesture(minimumDistance: 40)
                .onEnded(handleSwipe)
        )
        .defersSystemGestures(on: .horizontal)
        .sheet(isPresented: $isAddGradeSheetPresented) {
            addGradeSheet
        }
        .accessibilityAction(named: Text("Eelmine telk")) {
            if hasPrevious { navigate(to: tentNumber - 1) }
        }
        .accessibilityAction(named: Text("Järgmine telk")) {
            if hasNext { navigate(to: tentNumber + 1) }
        }
    }

    @ViewBuilder
    private var addGradeButton: some View {
        let action = {
            scoreText = ""
            scoreFeedback = nil
            isAddGradeSheetPresented = true
        }
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
                Image(systemName: "square.and.pencil")
                    .font(.title2)
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Lisa hinne")
        }
    }

    private var addGradeSheet: some View {
        NavigationStack {
            VStack {
                Text("Sisesta hinne")
                    .font(.title3)
                TextField("0", text: $scoreText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 80, alignment: .center)
                        .font(.largeTitle)
                        .onChange(of: scoreText, {
                            scoreText = String(scoreText.prefix(2))
                        })
                if let scoreFeedback {
                    Section {
                        switch scoreFeedback {
                        case .success(let message):
                            Text(message).foregroundStyle(.green)
                        case .error(let message):
                            Text(message).foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("\(tentNumber). telk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tühista") {
                        isAddGradeSheetPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvesta") {
                        submitScore(dismissOnSuccess: true)
                    }
                    .disabled(isSubmittingScore || Int(scoreText) == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func handleSwipe(_ value: DragGesture.Value) {
        let dx = value.translation.width
        let dy = value.translation.height
        guard abs(dx) > abs(dy) * 1.5, abs(dx) > 80 else { return }

        if dx > 0, hasPrevious {
            navigate(to: tentNumber - 1)
        } else if dx < 0, hasNext {
            navigate(to: tentNumber + 1)
        }
    }

    private var sortedScores: [TentScore] {
        scores.sorted { $0.createdAt > $1.createdAt }
    }

    private func loadScores() async {
        isLoadingScores = true
        scoresError = nil
        defer { isLoadingScores = false }
        do {
            scores = try await TentsAPI.fetch(shiftNr: shiftNr, tentNr: tentNumber)
        } catch {
            scoresError = error.localizedDescription
        }
    }

    private func submitScore(dismissOnSuccess: Bool = false) {
        guard let score = Int(scoreText) else { return }
        Task {
            isSubmittingScore = true
            scoreFeedback = nil
            defer { isSubmittingScore = false }
            do {
                try await TentsAPI.setScore(shiftNr: shiftNr, tentNr: tentNumber, score: score)
                scoreFeedback = .success("Salvestatud")
                scoreText = ""
                await loadScores()
                if dismissOnSuccess {
                    isAddGradeSheetPresented = false
                }
            } catch {
                scoreFeedback = .error(error.localizedDescription)
            }
        }
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
    @State private var selectedTab: HomeTab = .telgid

    init(tent: Int, records: [ShiftRecord]) {
        initialTent = tent
        self.records = records
        _path = State(initialValue: NavigationPath([tent]))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $path) {
                Text("Telgid")
                    .navigationTitle("Telgid")
                    .navigationDestination(for: Int.self) { n in
                        TentDetailView(
                            tentNumber: n,
                            shiftNr: 3,
                            records: n == initialTent ? records : [],
                            path: $path
                        )
                    }
            }
            .tabItem { Label("Telgid", systemImage: "tent.fill") }
            .tag(HomeTab.telgid)

            Text("Meeskonnad")
                .tabItem { Label("Meeskonnad", systemImage: "person.3.fill") }
                .tag(HomeTab.meeskonnad)
        }
        .environment(AppRouter())
    }
}

#Preview("Telk 2") {
    @Previewable @State var path = NavigationPath()
    @Previewable @State var selectedTab: HomeTab = .telgid
    
    let router = AppRouter()
    TentDetailPreviewHost(tent: 2, records: previewTentRecords).environment(router)
}

#Preview("Tühi telk") {
    TentDetailPreviewHost(tent: 2, records: [])
}

private let previewTentsTabRecords: [ShiftRecord] = previewTentRecords + [
    ShiftRecord(id: 10, childId: 201, childName: "Tõnis Tamm",
                teamId: 1, teamName: "Punased", tentNr: 4,
                isPresent: true, ageAtCamp: 11, year: 2026, shiftNr: 3),
    ShiftRecord(id: 11, childId: 202, childName: "Liisi Lepp",
                teamId: 2, teamName: "Sinised", tentNr: 4,
                isPresent: true, ageAtCamp: 13, year: 2026, shiftNr: 3),
    ShiftRecord(id: 12, childId: 203, childName: "Mart Mets",
                teamId: nil, teamName: nil, tentNr: 7,
                isPresent: false, ageAtCamp: 10, year: 2026, shiftNr: 3),
    ShiftRecord(id: 13, childId: 204, childName: "Telgita laps",
                teamId: 1, teamName: "Punased", tentNr: nil,
                isPresent: true, ageAtCamp: 9, year: 2026, shiftNr: 3),
]

#Preview("Telgid") {
    @Previewable @State var path = NavigationPath()
    @Previewable @State var selectedTab: HomeTab = .telgid
    TabView(selection: $selectedTab) {
        TentsTab(
            path: $path,
            records: previewTentsTabRecords,
            shiftNr: 3,
            isLoading: false,
            errorMessage: nil,
            reload: { }
        )
        .tabItem { Label("Telgid", systemImage: "tent.fill") }
        .tag(HomeTab.telgid)
    }
    .environment(AppRouter())
    .environment(AuthService())
}
