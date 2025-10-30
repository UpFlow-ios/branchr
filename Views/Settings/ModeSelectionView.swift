//
//  ModeSelectionView.swift
//  Branchr
//
//  Created by Joe Dormond on 2025-10-24.
//

import SwiftUI

struct ModeSelectionView: View {
    @ObservedObject var modeManager = ModeManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("🌐 Select Your Branchr Mode")
                    .font(.headline)
                    .padding(.top, 40)
                
                ForEach(BranchrMode.allCases, id: \.self) { mode in
                    Button(action: {
                        modeManager.setMode(mode)
                    }) {
                        VStack {
                            Text(mode.icon)
                                .font(.system(size: 40))
                            Text(mode.displayName)
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text(ModeConfiguration.preset(for: mode).description)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [.gray.opacity(0.3), modeManager.configuration.themeColor.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .navigationBarHidden(true)
        }
    }
}
