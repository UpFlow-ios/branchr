//
//  CloudStatusBannerView.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-25.
//

import SwiftUI

/// Banner view showing iCloud sync status
struct CloudStatusBannerView: View {
    @ObservedObject var syncService = RideCloudSyncService.shared
    @ObservedObject var preferenceSync = UserPreferenceSyncManager.shared
    @ObservedObject var watchService = WatchConnectivityService.shared
    @ObservedObject private var theme = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // iCloud Sync Status
            HStack {
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(theme.primaryText)
                    Text("Syncing to iCloud…")
                        .font(.caption)
                        .foregroundColor(theme.primaryText)
                } else if let error = syncService.syncError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(theme.errorColor)
                    Text("Sync Error")
                        .font(.caption)
                        .foregroundColor(theme.primaryText)
                } else {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(theme.primaryText)
                    Text("Last sync: \(syncService.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")")
                        .font(.caption)
                        .foregroundColor(theme.primaryText)
                }
                Spacer()
            }
            
            // Watch Connection Status
            if watchService.isWatchConnected {
                HStack {
                    Image(systemName: watchService.isWatchReachable ? "applewatch" : "applewatch.slash")
                        .foregroundColor(watchService.isWatchReachable ? theme.successColor : theme.warningColor)
                    Text(watchService.isWatchReachable ? "Watch Connected" : "Watch Disconnected")
                        .font(.caption)
                        .foregroundColor(theme.primaryText)
                    Spacer()
                }
            }
            
            // Preference Sync Status
            if let lastPreferenceSync = preferenceSync.lastSync {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(theme.accentColor)
                    Text("Prefs synced: \(lastPreferenceSync.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(theme.primaryText)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            theme.cardBackground
        )
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

/// Compact version for smaller spaces
struct CompactCloudStatusView: View {
    @ObservedObject var syncService = RideCloudSyncService.shared
    @ObservedObject var watchService = WatchConnectivityService.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // iCloud Status
            HStack(spacing: 4) {
                if syncService.isSyncing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(.white)
                } else {
                    Image(systemName: "icloud.and.arrow.up")
                        .foregroundColor(.white)
                }
                Text(syncService.isSyncing ? "Syncing" : "iCloud")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            
            // Watch Status
            if watchService.isWatchConnected {
                HStack(spacing: 4) {
                    Image(systemName: "applewatch")
                        .foregroundColor(watchService.isWatchReachable ? .green : .orange)
                    Text("Watch")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(.blue.opacity(0.7))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        CloudStatusBannerView()
        CompactCloudStatusView()
    }
    .padding()
    .background(.black)
}
