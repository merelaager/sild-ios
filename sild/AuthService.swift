//
//  AuthService.swift
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

    enum CodingKeys: String, CodingKey {
        case userId, name, nickname, email, currentShift, currentRole, isRoot, managedShifts
    }

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

struct JSendResponse<T: Decodable>: Decodable {
    let status: String
    let data: T?
    let message: String?
}

enum AuthState: Equatable {
    case checking
    case unauthenticated
    case authenticated(CurrentUser)
}

enum AuthError: LocalizedError {
    case invalidResponse
    case invalidCredentials
    case server(status: Int)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unexpected response from the server."
        case .invalidCredentials:
            return "Incorrect username or password."
        case .server(let status):
            return "Server error (\(status))."
        case .transport(let error):
            return error.localizedDescription
        case .decoding(let error):
            return "Failed to read server response: \(error.localizedDescription)"
        }
    }
}

@MainActor
@Observable
final class AuthService {
    private(set) var state: AuthState = .checking

    var currentUser: CurrentUser? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    /// Called on app launch to determine whether a session already exists.
    func refreshCurrentUser() async {
        do {
            let user = try await fetchCurrentUser()
            state = .authenticated(user)
        } catch {
            state = .unauthenticated
        }
    }

    func login(username: String, password: String) async throws {
        let url = API.baseURL.appendingPathComponent("api/auth/login")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            let user = try await fetchCurrentUser()
            state = .authenticated(user)
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }

    func logout() {
        state = .unauthenticated
    }

    private func fetchCurrentUser() async throws -> CurrentUser {
        let url = API.baseURL.appendingPathComponent("api/auth/me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        switch http.statusCode {
        case 200..<300:
            do {
                let envelope = try JSONDecoder().decode(JSendResponse<CurrentUser>.self, from: data)
                guard envelope.status == "success", let user = envelope.data else {
                    throw AuthError.invalidResponse
                }
                return user
            } catch let error as AuthError {
                throw error
            } catch {
                throw AuthError.decoding(error)
            }
        case 401, 403:
            throw AuthError.invalidCredentials
        default:
            throw AuthError.server(status: http.statusCode)
        }
    }
}
