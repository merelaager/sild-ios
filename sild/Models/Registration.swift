//
//  Registration.swift
//  sild
//

import Foundation

struct Registration: Codable, Identifiable, Equatable {
    let id: Int
    let childId: Int
    let child: RegistrationChild
    let shiftNr: Int
    let isOld: Bool
    let contactName: String?
    let contactNumber: String?
    let contactEmail: String?
}

struct RegistrationChild: Codable, Equatable {
    let name: String
    let sex: String
    let currentAge: Double
}
