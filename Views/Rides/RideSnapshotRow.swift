//
//  RideSnapshotRow.swift
//  branchr
//
//  Created for Phase 35C - Ride Snapshot Stats
//

import SwiftUI

struct RideSnapshotRow: View {
    let distanceMiles: Double
    let durationSeconds: TimeInterval
    let avgSpeed: Double

    var body: some View {
        HStack(spacing: 12) {
            SnapshotItem(
                title: "Distance",
                value: String(format: "%.2f mi", distanceMiles)
            )
            SnapshotItem(
                title: "Duration",
                value: formatDuration(durationSeconds)
            )
            SnapshotItem(
                title: "Avg Speed",
                value: String(format: "%.1f mph", avgSpeed)
            )
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

private struct SnapshotItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

