//
//  RegistrationsAPI.swift
//  sild
//

import Foundation

enum RegistrationsAPI {
    private struct Payload: Decodable {
        let registrations: [Registration]
    }

    static func fetch(shiftNr: Int) async throws -> [Registration] {
        let payload: Payload = try await APIClient.get(
            "api/registrations",
            query: [URLQueryItem(name: "shiftNr", value: String(shiftNr))],
            tag: "Registrations"
        )
        return payload.registrations
    }
}
