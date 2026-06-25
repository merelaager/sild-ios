//
//  TentScoringCoordinator.swift
//  sild
//

import SwiftUI

@MainActor
@Observable
final class TentScoringCoordinator {
    struct ActiveTent: Equatable {
        let tentNumber: Int
        let shiftNr: Int
    }

    var activeTent: ActiveTent?

    private(set) var sheetRequestId: Int = 0
    private(set) var previousRequestId: Int = 0
    private(set) var nextRequestId: Int = 0

    func setActive(tentNumber: Int, shiftNr: Int) {
        activeTent = ActiveTent(tentNumber: tentNumber, shiftNr: shiftNr)
    }

    func clearActive(forTent tentNumber: Int) {
        if activeTent?.tentNumber == tentNumber {
            activeTent = nil
        }
    }

    func requestSheet() {
        sheetRequestId &+= 1
    }

    func requestPrevious() {
        previousRequestId &+= 1
    }

    func requestNext() {
        nextRequestId &+= 1
    }
}

struct TentAccessoryControls: View {
    let scoring: TentScoringCoordinator

    private var hasPrevious: Bool { (scoring.activeTent?.tentNumber ?? 1) > 1 }
    private var hasNext: Bool { (scoring.activeTent?.tentNumber ?? 10) < 10 }

    var body: some View {
        HStack {
            Button { scoring.requestPrevious() } label: {
                Image(systemName: "chevron.backward")
                    .fontWeight(.semibold)
                    .frame(width: 40, height: 40)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .disabled(!hasPrevious)
            .accessibilityLabel("Eelmine telk")

            Spacer()

            Button { scoring.requestSheet() } label: {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
            }
            .accessibilityLabel("Lisa hinne")

            Spacer()

            Button { scoring.requestNext() } label: {
                Image(systemName: "chevron.forward")
                    .fontWeight(.semibold)
                    .frame(width: 40, height: 40)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .disabled(!hasNext)
            .accessibilityLabel("Järgmine telk")
        }
    }
}
