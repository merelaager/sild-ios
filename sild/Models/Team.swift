//
//  Team.swift
//  sild
//

import Foundation

struct Team: Codable, Identifiable, Equatable {
    let id: Int
    let shiftNr: Int
    let name: String
    let year: Int
    let place: Int?
    let captainId: Int?
}
