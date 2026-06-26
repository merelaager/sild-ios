//
//  ContentView.swift
//  sild
//

import SwiftUI

struct AppView: View {
    @Environment(AuthService.self) private var auth

    @State private var records = ShiftRecordsStore()
    @State private var teams = TeamsStore()
    @State private var registrations = RegistrationsStore()
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
                    HomeView(
                        user: user,
                        records: records,
                        teams: teams,
                        registrations: registrations
                    )
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
                let recordsCached = records.hydrate(shiftNr: shiftNr)
                teams.hydrate(shiftNr: shiftNr)
                registrations.hydrate(shiftNr: shiftNr)

                Task { await teams.load(shiftNr: shiftNr) }
                Task { await registrations.load(shiftNr: shiftNr) }

                if recordsCached {
                    Task { await records.load(shiftNr: shiftNr) }
                } else {
                    await records.load(shiftNr: shiftNr)
                }
            }
            didBootstrap = true
        }
    }
}

#Preview {
    AppView()
        .environment(AuthService())
        .environment(AppRouter())
}
