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
        print("[Router] handle url=\(url.absoluteString)")
        guard let host = url.host(), host == "sild.merelaager.ee" else {
            print("[Router] reject: unexpected host=\(url.host() ?? "nil")")
            return false
        }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count == 2,
              parts[0] == "telgid",
              let tent = Int(parts[1]),
              (1...10).contains(tent)
        else {
            print("[Router] reject: path parts=\(parts)")
            return false
        }
        pendingTentNumber = tent
        print("[Router] accepted: pendingTentNumber=\(tent)")
        return true
    }
}
