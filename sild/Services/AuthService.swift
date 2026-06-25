//
//  AuthService.swift
//  sild
//

import Foundation

enum AuthState: Equatable {
    case checking
    case unauthenticated
    case authenticated(CurrentUser)
}

@MainActor
@Observable
final class AuthService {
    private(set) var state: AuthState = .checking

    var currentUser: CurrentUser? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    private struct LoginBody: Encodable {
        let username: String
        let password: String
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
        try await APIClient.post(
            "api/auth/login",
            body: LoginBody(username: username, password: password),
            tag: "Auth"
        )
        let user = try await fetchCurrentUser()
        state = .authenticated(user)
    }

    func logout() {
        state = .unauthenticated
    }

    private func fetchCurrentUser() async throws -> CurrentUser {
        try await APIClient.get("api/auth/me", tag: "Auth")
    }
}
