//
//  TeamsAPI.swift
//  sild
//

import Foundation

enum TeamsAPI {
    private struct Payload: Decodable {
        let teams: [Team]
    }

    static func fetch(shiftNr: Int) async throws -> [Team] {
        let payload: Payload = try await APIClient.get(
            "api/teams",
            query: [URLQueryItem(name: "shiftNr", value: String(shiftNr))],
            tag: "Teams"
        )
        return payload.teams
    }

    private struct CreateBody: Encodable {
        let shiftNr: Int
        let name: String
    }

    static func create(shiftNr: Int, name: String) async throws {
        try await APIClient.post(
            "api/teams",
            body: CreateBody(shiftNr: shiftNr, name: name),
            tag: "Teams"
        )
    }
}
