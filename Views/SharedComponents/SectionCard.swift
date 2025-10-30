//
//  SectionCard.swift
//  branchr
//
//  Created by Joe Dormond on 2025-10-26.
//

import SwiftUI

/// Reusable section card for settings, voice, and other structured screens
struct SectionCard<Content: View>: View {
    @ObservedObject var theme = ThemeManager.shared
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.bold())
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 4)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            theme.isDarkMode
                ? Color.white.opacity(0.05)
                : Color.black.opacity(0.06)
        )
        .cornerRadius(16)
        .shadow(radius: 4)
        .padding(.horizontal, 16)
    }
}

