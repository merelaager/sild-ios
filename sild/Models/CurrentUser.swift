//
//  CurrentUser.swift
//  sild
//

import Foundation

struct CurrentUser: Codable, Equatable {
    var userId: Int
    var name: String
    var nickname: String?
    var email: String
    var currentShift: Int?
    var currentRole: String?
    var isRoot: Bool
    var managedShifts: [Int]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        userId = try c.decode(Int.self, forKey: .userId)
        name = try c.decode(String.self, forKey: .name)
        nickname = try c.decodeIfPresent(String.self, forKey: .nickname)
        email = try c.decode(String.self, forKey: .email)
        currentShift = try c.decodeIfPresent(Int.self, forKey: .currentShift)
        currentRole = try c.decodeIfPresent(String.self, forKey: .currentRole)
        isRoot = try c.decodeIfPresent(Bool.self, forKey: .isRoot) ?? false
        managedShifts = try c.decodeIfPresent([Int].self, forKey: .managedShifts) ?? []
    }
}
