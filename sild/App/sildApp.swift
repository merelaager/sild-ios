//
//  sildApp.swift
//  sild
//

import SwiftUI

@main
struct sildApp: App {
    @State private var auth = AuthService()
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            AppView()
                .environment(auth)
                .environment(router)
                .onOpenURL { router.handle(url: $0) }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        router.handle(url: url)
                    }
                }
        }
    }
}
