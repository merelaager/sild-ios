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

private struct RegistrationsPayload: Decodable {
    let registrations: [Registration]
}

enum RegistrationsAPI {
    static func fetch(shiftNr: Int) async throws -> [Registration] {
        var components = URLComponents(
            url: API.baseURL.appendingPathComponent("api/registrations"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [URLQueryItem(name: "shiftNr", value: String(shiftNr))]
        guard let url = components.url else {
            throw AuthError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        print("[Registrations] GET \(url.absoluteString)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("[Registrations] transport error: \(error)")
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        print("[Registrations] status \(http.statusCode) body: \(String(data: data, encoding: .utf8) ?? "<binary>")")

        switch http.statusCode {
        case 200..<300:
            do {
                let envelope = try JSONDecoder().decode(JSendResponse<RegistrationsPayload>.self, from: data)
                guard envelope.status == "success", let payload = envelope.data else {
                    throw AuthError.invalidResponse
                }
                return payload.registrations
            } catch let error as AuthError {
                throw error
            } catch {
                print("[Registrations] decoding error: \(error)")
                throw AuthError.decoding(error)
            }
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }
}
