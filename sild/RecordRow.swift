//
//  RecordRow.swift
//  sild
//

import SwiftUI

struct RecordRow: View {
    let record: ShiftRecord
    var showsTent: Bool = false
    var showsTeam: Bool = false
    var onTogglePresence: (() async -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.childName)
                    .font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let onTogglePresence {
                PresenceCheckbox(isPresent: record.isPresent, action: onTogglePresence)
            } else if !record.isPresent {
                Image(systemName: "person.slash")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Puudub")
            }
        }
        .padding(.vertical, 2)
    }

    private var subtitle: String {
        var parts: [String] = ["\(record.ageAtCamp)a"]
        if showsTent, let tent = record.tentNr {
            parts.append("Telk \(tent)")
        }
        if showsTeam, let team = record.teamName, !team.isEmpty {
            parts.append(team)
        }
        return parts.joined(separator: " · ")
    }
}

private struct PresenceCheckbox: View {
    let isPresent: Bool
    let action: () async -> Void

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            Image(systemName: isPresent ? "checkmark.square.fill" : "square")
                .font(.title2)
                .foregroundStyle(isPresent ? Color.accentColor : Color.secondary)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
    }
}
