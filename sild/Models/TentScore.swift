//
//  TentScore.swift
//  sild
//

import Foundation

struct TentScore: Decodable, Identifiable {
    let scoreId: Int
    let score: Double
    let createdAt: String

    var id: Int { scoreId }

    var createdAtDate: Date? {
        try? Date(createdAt, strategy: .iso8601)
    }
}
