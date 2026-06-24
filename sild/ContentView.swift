//
//  ContentView.swift
//  sild
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth

    var body: some View {
        Group {
            switch auth.state {
            case .checking:
                ProgressView()
            case .unauthenticated:
                LoginView()
            case .authenticated(let user):
                HomeView(user: user)
            }
        }
        .task {
            if case .checking = auth.state {
                await auth.refreshCurrentUser()
            }
        }
    }
}

#Preview {
    let auth = AuthService()
    let router = AppRouter()
    return ContentView()
        .environment(auth)
        .environment(router)
}
