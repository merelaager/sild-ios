//
//  TentsAPI.swift
//  sild
//

import Foundation

enum TentsAPI {
    private struct Payload: Decodable {
        let scores: [TentScore]
    }

    private struct ScoreBody: Encodable {
        let score: Int
    }

    static func fetchScores(shiftNr: Int, tentNr: Int) async throws -> [TentScore] {
        let payload: Payload = try await APIClient.get(
            "api/shifts/\(shiftNr)/tents/\(tentNr)",
            tag: "Tents"
        )
        return payload.scores
    }

    static func setScore(shiftNr: Int, tentNr: Int, score: Int) async throws {
        try await APIClient.post(
            "api/shifts/\(shiftNr)/tents/\(tentNr)",
            body: ScoreBody(score: score),
            tag: "Tents"
        )
    }
}
