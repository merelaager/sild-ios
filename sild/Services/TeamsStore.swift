//
//  TeamsStore.swift
//  sild
//

import Foundation

@MainActor
@Observable
final class TeamsStore {
    private(set) var teams: [Team] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var loadedShiftNr: Int?

    init() {}

    init(previewTeams: [Team], shiftNr: Int) {
        self.teams = sorted(previewTeams)
        self.loadedShiftNr = shiftNr
    }

    @discardableResult
    func hydrate(shiftNr: Int) -> Bool {
        guard loadedShiftNr != shiftNr else { return false }
        guard let cached: [Team] = DiskCache.read(key: cacheKey(shiftNr: shiftNr)) else {
            return false
        }
        teams = sorted(cached)
        loadedShiftNr = shiftNr
        return true
    }

    func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await TeamsAPI.fetch(shiftNr: shiftNr)
            teams = sorted(fetched)
            loadedShiftNr = shiftNr
            DiskCache.write(fetched, key: cacheKey(shiftNr: shiftNr))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func sorted(_ items: [Team]) -> [Team] {
        items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func cacheKey(shiftNr: Int) -> String {
        "teams-\(shiftNr)"
    }
}
