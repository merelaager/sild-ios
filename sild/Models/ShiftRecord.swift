//
//  ShiftRecord.swift
//  sild
//

import Foundation

struct ShiftRecord: Codable, Identifiable, Equatable {
    let id: Int
    let childId: Int
    let childName: String
    var teamId: Int?
    var teamName: String?
    var tentNr: Int?
    var isPresent: Bool
    let ageAtCamp: Int
    let year: Int
    let shiftNr: Int
}

extension Array where Element == ShiftRecord {
    func sortedByName() -> [ShiftRecord] {
        sorted { $0.childName.localizedCaseInsensitiveCompare($1.childName) == .orderedAscending }
    }
}
