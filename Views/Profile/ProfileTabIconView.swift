//
//  ProfileTabIconView.swift
//  branchr
//
//  Created by Joseph Dormond on 2025-11-05
//  Phase 31 - Profile Tab Icon with Photo
//  Phase 34 - Green online ring indicator
//

import SwiftUI

/**
 * 👤 Profile Tab Icon View
 *
 * Shows user's profile photo on the tab bar if available,
 * otherwise shows default person icon.
 * Phase 34: Includes green ring when online.
 */
struct ProfileTabIconView: View {
    @ObservedObject private var profileService = FirebaseProfileService.shared
    @ObservedObject private var presence = PresenceManager.shared // Phase 34: Online presence
    
    var body: some View {
        ZStack {
            // Phase 34: Green ring when online
            if presence.isOnline {
                Circle()
                    .stroke(Color.green, lineWidth: 2)
                    .frame(width: 28, height: 28)
            }
            
            // Profile image
            Group {
                if let photoURL = profileService.currentProfile.photoURL, !photoURL.isEmpty,
                   let url = URL(string: photoURL) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 22))
                    }
                    .frame(width: 26, height: 26)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 22))
                }
            }
        }
    }
}

