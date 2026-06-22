//
//  sildApp.swift
//  sild
//

import SwiftUI

@main
struct sildApp: App {
    @State private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(auth)
        }
    }
}
