//
//  ContentView.swift
//  sild
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthService.self) private var auth

    @State private var store = ShiftRecordsStore()
    @State private var didBootstrap = false

    var body: some View {
        Group {
            if !didBootstrap {
                SplashView()
            } else {
                switch auth.state {
                case .checking:
                    SplashView()
                case .unauthenticated:
                    LoginView()
                case .authenticated(let user):
                    HomeView(user: user, store: store)
                }
            }
        }
        .task {
            guard !didBootstrap else { return }
            if case .checking = auth.state {
                await auth.refreshCurrentUser()
            } else {
                Task { await auth.refreshCurrentUser() }
            }
            if case .authenticated(let user) = auth.state,
               let shiftNr = user.currentShift {
                await store.load(shiftNr: shiftNr)
            }
            didBootstrap = true
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthService())
        .environment(AppRouter())
}
