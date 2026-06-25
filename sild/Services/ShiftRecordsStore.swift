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

    func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            records = try await ShiftRecordsAPI.fetch(shiftNr: shiftNr)
            loadedShiftNr = shiftNr
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
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex][keyPath: keyPath] = original
            }
        }
    }
}
