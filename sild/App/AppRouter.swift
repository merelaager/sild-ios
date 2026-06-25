//
//  AppRouter.swift
//  sild
//

import Foundation

@MainActor
@Observable
final class AppRouter {
    var pendingTentNumber: Int?

    @discardableResult
    func handle(url: URL) -> Bool {
        guard let host = url.host(), host == "sild.merelaager.ee" else { return false }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2,
              parts[0] == "telgid",
              let tent = Int(parts[1]),
              (1...10).contains(tent)
        else {
            return false
        }
        pendingTentNumber = tent
        return true
    }
}
