//
//  ShiftRecordsStore.swift
//  sild
//

import Foundation

@MainActor
@Observable
final class ShiftRecordsStore {
    private(set) var records: [ShiftRecord] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var loadedShiftNr: Int?

    init() {}

    init(previewRecords: [ShiftRecord], shiftNr: Int) {
        self.records = previewRecords
        self.loadedShiftNr = shiftNr
    }

    /// Synchronously populate from disk cache. Returns true on hit.
    @discardableResult
    func hydrate(shiftNr: Int) -> Bool {
        guard loadedShiftNr != shiftNr else { return false }
        guard let cached: [ShiftRecord] = DiskCache.read(key: cacheKey(shiftNr: shiftNr)) else {
            return false
        }
        records = cached
        loadedShiftNr = shiftNr
        return true
    }

    func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await ShiftRecordsAPI.fetch(shiftNr: shiftNr)
            records = fetched
            loadedShiftNr = shiftNr
            DiskCache.write(fetched, key: cacheKey(shiftNr: shiftNr))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setPresence(recordId: Int, isPresent: Bool) async {
        await mutate(recordId: recordId, apply: { $0.isPresent = isPresent }, restore: \.isPresent) {
            try await ShiftRecordsAPI.setPresence(recordId: recordId, isPresent: isPresent)
        }
    }

    func setTent(recordId: Int, tentNr: Int?) async {
        await mutate(recordId: recordId, apply: { $0.tentNr = tentNr }, restore: \.tentNr) {
            try await ShiftRecordsAPI.setTent(recordId: recordId, tentNr: tentNr)
        }
    }

    func setTeam(recordId: Int, teamId: Int?, teamName: String?) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let originalId = records[index].teamId
        let originalName = records[index].teamName
        guard originalId != teamId else { return }
        records[index].teamId = teamId
        records[index].teamName = teamName
        do {
            try await ShiftRecordsAPI.setTeam(recordId: recordId, teamId: teamId)
            persist()
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].teamId = originalId
                records[revertIndex].teamName = originalName
            }
        }
    }

    private func mutate<Value: Equatable>(
        recordId: Int,
        apply: (inout ShiftRecord) -> Void,
        restore keyPath: WritableKeyPath<ShiftRecord, Value>,
        request: () async throws -> Void
    ) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let original = records[index][keyPath: keyPath]
        apply(&records[index])
        guard records[index][keyPath: keyPath] != original else { return }
        do {
            try await request()
            persist()
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex][keyPath: keyPath] = original
            }
        }
    }

    private func cacheKey(shiftNr: Int) -> String {
        "records-\(shiftNr)"
    }

    private func persist() {
        guard let shiftNr = loadedShiftNr else { return }
        DiskCache.write(records, key: cacheKey(shiftNr: shiftNr))
    }
}
