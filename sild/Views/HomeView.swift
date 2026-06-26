//
//  HomeView.swift
//  sild
//

import SwiftUI

enum HomeTab: Hashable {
    case telgid, meeskonnad, sätted, search
}

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    let user: CurrentUser
    let records: ShiftRecordsStore
    let teams: TeamsStore
    let registrations: RegistrationsStore

    @State private var scoring = TentScoringCoordinator()
    @State private var selectedTab: HomeTab = .telgid
    @State private var tentsPath = NavigationPath()
    @State private var childrenPath = NavigationPath()

    var body: some View {
        if let shiftNr = user.currentShift {
            TabView(selection: $selectedTab) {
                Tab("Telgid", systemImage: "tent", value: HomeTab.telgid) {
                    TentsTab(store: records, scoring: scoring, shiftNr: shiftNr, path: $tentsPath)
                }

                Tab("Meeskonnad", systemImage: "figure.sailing", value: HomeTab.meeskonnad) {
                    TeamsTab(records: records, teams: teams, shiftNr: shiftNr)
                }

                Tab("Sätted", systemImage: "gear", value: HomeTab.sätted) {
                    SettingsTab()
                }

                Tab("Otsi", systemImage: "magnifyingglass", value: HomeTab.search, role: .search) {
                    ChildrenTab(
                        records: records,
                        teams: teams,
                        registrations: registrations,
                        path: $childrenPath
                    )
                }
            }
            .tabBarMinimizeOnScrollDownIfAvailable()
            .tabViewBottomAccessoryIfAvailable(
                isEnabled: !tentsPath.isEmpty && selectedTab == .telgid
            ) {
                TentAccessoryControls(scoring: scoring)
            }
            .task(id: shiftNr) {
                if records.loadedShiftNr != shiftNr {
                    await records.load(shiftNr: shiftNr)
                }
                if teams.loadedShiftNr != shiftNr {
                    Task { await teams.load(shiftNr: shiftNr) }
                }
                if registrations.loadedShiftNr != shiftNr {
                    Task { await registrations.load(shiftNr: shiftNr) }
                }
            }
            .onChange(of: router.pendingTentNumber, initial: true) { _, new in
                guard let tent = new else { return }
                Task { @MainActor in
                    selectedTab = .telgid
                    tentsPath = NavigationPath([tent])
                    router.pendingTentNumber = nil
                }
            }
        } else {
            ContentUnavailableView(
                "No current shift",
                systemImage: "calendar.badge.exclamationmark",
                description: Text("You're not assigned to a shift right now.")
            )
        }
    }
}

extension View {
    @ViewBuilder
    func tabBarMinimizeOnScrollDownIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }

    @ViewBuilder
    func tabViewBottomAccessoryIfAvailable<Content: View>(
        isEnabled: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if #available(iOS 26.1, *) {
            self.tabViewBottomAccessory(isEnabled: isEnabled, content: content)
        } else if #available(iOS 26.0, *) {
            if isEnabled {
                self.tabViewBottomAccessory(content: content)
            } else {
                self
            }
        } else {
            self
        }
    }
}
