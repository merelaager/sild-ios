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
}
