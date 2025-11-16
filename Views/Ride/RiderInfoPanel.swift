//
//  RiderInfoPanel.swift
//  branchr
//
//  Created for Phase 4 - Interactive Rider Info Panel
//

import SwiftUI

/// Bottom card panel showing rider information when tapped
struct RiderInfoPanel: View {
    let name: String
    let speed: Double
    let distance: Double
    let profileImage: UIImage?
    let isHost: Bool
    
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile picture or fallback
            if let img = profileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.green, lineWidth: 3))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                Circle()
                    .fill(isHost ? Color.branchrAccent : Color.red)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.green, lineWidth: 3))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            
            Text(name)
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            if isHost {
                Text("Host")
                    .font(.caption)
                    .foregroundColor(Color.branchrAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.branchrAccent.opacity(0.2))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 20) {
                VStack {
                    Text("Speed")
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.7))
                    Text("\(speed, specifier: "%.1f") mph")
                        .font(.title3)
                        .bold()
                        .foregroundColor(theme.primaryText)
                }
                
                VStack {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(theme.primaryText.opacity(0.7))
                    Text("\(distance, specifier: "%.2f") mi")
                        .font(.title3)
                        .bold()
                        .foregroundColor(theme.primaryText)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(theme.cardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

