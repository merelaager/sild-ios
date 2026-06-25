//
//  RegistrationsStore.swift
//  sild
//

import Foundation

@MainActor
@Observable
final class RegistrationsStore {
    private(set) var registrations: [Registration] = []
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?
    private(set) var loadedShiftNr: Int?

    @discardableResult
    func hydrate(shiftNr: Int) -> Bool {
        guard loadedShiftNr != shiftNr else { return false }
        guard let cached: [Registration] = DiskCache.read(key: cacheKey(shiftNr: shiftNr)) else {
            return false
        }
        registrations = cached
        loadedShiftNr = shiftNr
        return true
    }

    func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let fetched = try await RegistrationsAPI.fetch(shiftNr: shiftNr)
            registrations = fetched
            loadedShiftNr = shiftNr
            DiskCache.write(fetched, key: cacheKey(shiftNr: shiftNr))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func registration(for childId: Int) -> Registration? {
        registrations.first { $0.childId == childId }
    }

    private func cacheKey(shiftNr: Int) -> String {
        "registrations-\(shiftNr)"
    }
}
