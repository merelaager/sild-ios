//
//  ShiftRecordsAPI.swift
//  sild
//

import Foundation

enum ShiftRecordsAPI {
    private struct Payload: Decodable {
        let records: [ShiftRecord]
    }

    private struct PresenceBody: Encodable {
        let isPresent: Bool
    }

    private struct TentBody: Encodable {
        let tentNr: Int?
    }

    private struct TeamBody: Encodable {
        let teamId: Int?
    }

    static func fetch(shiftNr: Int) async throws -> [ShiftRecord] {
        let payload: Payload = try await APIClient.get(
            "api/records",
            query: [URLQueryItem(name: "shiftNr", value: String(shiftNr))],
            tag: "Records"
        )
        return payload.records
    }

    static func setPresence(recordId: Int, isPresent: Bool) async throws {
        try await APIClient.patch(
            "api/records/\(recordId)",
            body: PresenceBody(isPresent: isPresent),
            tag: "Records"
        )
    }

    static func setTent(recordId: Int, tentNr: Int?) async throws {
        try await APIClient.patch(
            "api/records/\(recordId)",
            body: TentBody(tentNr: tentNr),
            tag: "Records"
        )
    }

    static func setTeam(recordId: Int, teamId: Int?) async throws {
        try await APIClient.patch(
            "api/records/\(recordId)",
            body: TeamBody(teamId: teamId),
            tag: "Records"
        )
    }
}
