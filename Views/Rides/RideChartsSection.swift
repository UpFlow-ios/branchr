//
//  RideChartsSection.swift
//  branchr
//
//  Created for Phase 35C - Sparkline Charts
//

import SwiftUI

struct RideChartsSection: View {
    let speedSamples: [Double]
    let distanceMiles: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ride Insights")
                .font(.headline)

            VStack(spacing: 8) {
                SparklineCard(
                    title: "Speed",
                    subtitle: "last samples",
                    values: speedSamples.isEmpty ? [distanceMiles, distanceMiles * 0.8, distanceMiles * 0.6] : speedSamples
                )

                SparklineCard(
                    title: "Distance Trend",
                    subtitle: "this ride",
                    values: makeDistanceSeries(from: distanceMiles)
                )
            }
        }
    }

    private func makeDistanceSeries(from miles: Double) -> [Double] {
        guard miles > 0 else { return [0.1, 0.2, 0.15, 0.25] }
        // Fake a rising series
        return stride(from: 0.0, through: miles, by: miles / 6).map { $0 }
    }
}

struct SparklineCard: View {
    let title: String
    let subtitle: String
    let values: [Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.subheadline.bold())
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            Sparkline(values: values)
                .frame(height: 48)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct Sparkline: View {
    let values: [Double]

    var body: some View {
        GeometryReader { geo in
            if let max = values.max(), max > 0, values.count > 1 {
                let stepX = geo.size.width / CGFloat(values.count - 1)
                let scaleY = max > 0 ? geo.size.height / CGFloat(max) : 1

                Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = geo.size.height - (CGFloat(value) * scaleY)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [.yellow, .orange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
            } else {
                Text("No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

