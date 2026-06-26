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
    static let userCacheKey = "current-user"

    private(set) var state: AuthState

    init() {
        if let cached: CurrentUser = DiskCache.read(key: Self.userCacheKey) {
            self.state = .authenticated(cached)
        } else {
            self.state = .checking
        }
    }

    var currentUser: CurrentUser? {
        if case .authenticated(let user) = state { return user }
        return nil
    }

    private struct LoginBody: Encodable {
        let username: String
        let password: String
    }

    /// Called on app launch to determine whether a session already exists.
    /// On transport errors (no network) we keep any cached user so the app
    /// can be used offline; on an explicit 401 we clear the cached user.
    func refreshCurrentUser() async {
        do {
            let user = try await fetchCurrentUser()
            DiskCache.write(user, key: Self.userCacheKey)
            state = .authenticated(user)
        } catch APIError.unauthorized {
            DiskCache.remove(key: Self.userCacheKey)
            state = .unauthenticated
        } catch {
            if case .checking = state {
                state = .unauthenticated
            }
        }
    }

    func login(username: String, password: String) async throws {
        try await APIClient.post(
            "api/auth/login",
            body: LoginBody(username: username, password: password),
            tag: "Auth"
        )
        let user = try await fetchCurrentUser()
        DiskCache.write(user, key: Self.userCacheKey)
        state = .authenticated(user)
    }

    func logout() {
        DiskCache.remove(key: Self.userCacheKey)
        state = .unauthenticated
    }

    private func fetchCurrentUser() async throws -> CurrentUser {
        try await APIClient.get("api/auth/me", tag: "Auth")
    }
}
