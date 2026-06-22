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

private struct TeamsPayload: Decodable {
    let teams: [Team]
}

enum TeamsAPI {
    static func fetch(shiftNr: Int) async throws -> [Team] {
        var components = URLComponents(
            url: API.baseURL.appendingPathComponent("api/teams"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "shiftNr", value: String(shiftNr))]
        guard let url = components.url else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("[Teams] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Teams] transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        print("[Teams] status \(http.statusCode) body: \(String(data: data, encoding: .utf8) ?? "<binary>")")

        switch http.statusCode {
        case 200..<300:
            do {
                let envelope = try JSONDecoder().decode(JSendResponse<TeamsPayload>.self, from: data)
                guard envelope.status == "success", let payload = envelope.data else {
                    throw AuthError.invalidResponse
                }
                return payload.teams
            } catch let error as AuthError {
                throw error
            } catch {
                print("[Teams] decoding error: \(error)")
                throw AuthError.decoding(error)
            }
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }
}
