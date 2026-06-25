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

    @State private var store = ShiftRecordsStore()
    @State private var scoring = TentScoringCoordinator()
    @State private var selectedTab: HomeTab = .telgid
    @State private var tentsPath = NavigationPath()
    @State private var childrenPath = NavigationPath()

    var body: some View {
        if let shiftNr = user.currentShift {
            TabView(selection: $selectedTab) {
                Tab("Telgid", systemImage: "tent", value: HomeTab.telgid) {
                    TentsTab(store: store, scoring: scoring, shiftNr: shiftNr, path: $tentsPath)
                }

                Tab("Meeskonnad", systemImage: "figure.sailing", value: HomeTab.meeskonnad) {
                    TeamsTab(store: store, shiftNr: shiftNr)
                }

                Tab("Sätted", systemImage: "gear", value: HomeTab.sätted) {
                    SettingsTab()
                }

                Tab("Otsi", systemImage: "magnifyingglass", value: HomeTab.search, role: .search) {
                    ChildrenTab(store: store, path: $childrenPath)
                }
            }
            .tabBarMinimizeOnScrollDownIfAvailable()
            .tabViewBottomAccessoryIfAvailable(isEnabled: scoring.activeTent != nil) {
                TentAccessoryControls(scoring: scoring)
            }
            .task(id: shiftNr) { await store.load(shiftNr: shiftNr) }
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
