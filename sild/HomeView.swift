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

    @State private var records: [ShiftRecord] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var selectedTab: HomeTab = .telgid
    @State private var tentsPath = NavigationPath()
    @State private var childrenPath = NavigationPath()

    var body: some View {
        if let shiftNr = user.currentShift {
            TabView(selection: $selectedTab) {
                Tab("Telgid", systemImage: "tent", value: HomeTab.telgid) {
                    TentsTab(
                        path: $tentsPath,
                        records: records,
                        shiftNr: shiftNr,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        reload: { await load(shiftNr: shiftNr) }
                    )
                }

                Tab("Meeskonnad", systemImage: "figure.sailing", value: HomeTab.meeskonnad) {
                    TeamsTab(
                        records: records,
                        shiftNr: shiftNr,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        reload: { await load(shiftNr: shiftNr) }
                    )
                }

                Tab("Sätted", systemImage: "gear", value: HomeTab.sätted) {
                    SettingsTab()
                }

                Tab("Otsi", systemImage: "magnifyingglass", value: HomeTab.search, role: .search) {
                    ChildrenTab(
                        path: $childrenPath,
                        records: records,
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        reload: { await load(shiftNr: shiftNr) },
                        setPresence: { id, value in await setPresence(recordId: id, isPresent: value) },
                        setTent: { id, value in await setTent(recordId: id, tentNr: value) },
                        setTeam: { id, teamId, teamName in await setTeam(recordId: id, teamId: teamId, teamName: teamName) }
                    )
                }
            }
            .tabBarMinimizeOnScrollDownIfAvailable()
            .task(id: shiftNr) { await load(shiftNr: shiftNr) }
            .onChange(of: router.pendingTentNumber, initial: true) { _, new in
                print("[HomeView] onChange pendingTentNumber=\(String(describing: new)), selectedTab=\(selectedTab)")
                guard let tent = new else { return }
                Task { @MainActor in
                    print("[HomeView] navigating to tent \(tent)")
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

    private func load(shiftNr: Int) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            records = try await ShiftRecordsAPI.fetch(shiftNr: shiftNr)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setPresence(recordId: Int, isPresent: Bool) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let original = records[index].isPresent
        guard original != isPresent else { return }
        records[index].isPresent = isPresent
        do {
            try await ShiftRecordsAPI.setPresence(recordId: recordId, isPresent: isPresent)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].isPresent = original
            }
        }
    }

    private func setTent(recordId: Int, tentNr: Int?) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let original = records[index].tentNr
        guard original != tentNr else { return }
        records[index].tentNr = tentNr
        do {
            try await ShiftRecordsAPI.setTent(recordId: recordId, tentNr: tentNr)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].tentNr = original
            }
        }
    }

    private func setTeam(recordId: Int, teamId: Int?, teamName: String?) async {
        guard let index = records.firstIndex(where: { $0.id == recordId }) else { return }
        let originalId = records[index].teamId
        let originalName = records[index].teamName
        guard originalId != teamId else { return }
        records[index].teamId = teamId
        records[index].teamName = teamName
        do {
            try await ShiftRecordsAPI.setTeam(recordId: recordId, teamId: teamId)
        } catch {
            if let revertIndex = records.firstIndex(where: { $0.id == recordId }) {
                records[revertIndex].teamId = originalId
                records[revertIndex].teamName = originalName
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func tabBarMinimizeOnScrollDownIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
}
