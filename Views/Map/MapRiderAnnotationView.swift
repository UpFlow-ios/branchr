//
//  MapRiderAnnotationView.swift
//  branchr
//
//  Created for Smart Group Ride System - Rider Map Annotations
//

import SwiftUI

/// Circular rider avatar with optional green online ring
struct MapRiderAnnotationView: View {
    let name: String
    let photoURL: String?
    let isOnline: Bool
    
    var body: some View {
        ZStack {
            if isOnline {
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 44, height: 44)
            }
            
            if let urlString = photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                        .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.25))
                    .frame(width: 40, height: 40)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                    .overlay(Circle().stroke(Color.yellow.opacity(0.7), lineWidth: 1))
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
            }
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 16) {
        MapRiderAnnotationView(name: "Joe", photoURL: nil, isOnline: true)
        MapRiderAnnotationView(name: "Sam", photoURL: nil, isOnline: false)
    }.padding()
}


