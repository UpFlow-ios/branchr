//
//  ModeStatusBannerView.swift
//  Branchr
//
//  Created by Joe Dormond on 2025-10-24.
//

import SwiftUI

struct ModeStatusBannerView: View {
    @ObservedObject var modeManager = ModeManager.shared
    @State private var showSelector = false
    
    var body: some View {
        VStack {
            HStack {
                Text("\(modeManager.activeMode.icon) \(modeManager.activeMode.displayName)")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(10)
                    .glassEffect(.regular, in: .roundedRectangle(radius: 12))
                    .tint(modeManager.configuration.themeColor)
                    .interactive(true)
                    .onTapGesture {
                        showSelector.toggle()
                    }
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showSelector) {
            ModeSelectionView()
        }
    }
}
