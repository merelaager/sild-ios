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
            ContentView()
                .environment(auth)
                .environment(router)
                .onOpenURL { url in
                    print("[App] onOpenURL: \(url.absoluteString)")
                    router.handle(url: url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        print("[App] onContinueUserActivity browsing url: \(url.absoluteString)")
                        router.handle(url: url)
                    } else {
                        print("[App] onContinueUserActivity browsing without webpageURL")
                    }
                }
        }
    }
}
