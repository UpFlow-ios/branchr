//
//  ArtworkTint.swift
//  branchr
//
//  Dynamic UI Tint Based on Album Artwork
//  Created for Phase 76C - Apple Music Style Artwork Integration
//

import SwiftUI
import UIKit
import CoreImage

/**
 * 🎨 Artwork Tint Service
 *
 * Extracts dominant color from Apple Music artwork and
 * dynamically tints the UI to match, creating a unified visual experience.
 *
 * This matches the behavior of Apple Music's full-screen player.
 */
class ArtworkTint: ObservableObject {
    static let shared = ArtworkTint()
    
    @Published var dominantColor: Color = .white.opacity(0.22)
    
    private init() {}
    
    /// Update the dominant color based on new artwork
    func update(from image: UIImage?) {
        guard let image = image else {
            // Reset to default if no image
            DispatchQueue.main.async {
                self.dominantColor = .white.opacity(0.22)
            }
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let color = self.extractDominantColor(from: image)
            
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.dominantColor = color
                }
            }
        }
    }
    
    private func extractDominantColor(from image: UIImage) -> Color {
        guard let ciImage = CIImage(image: image) else {
            return .white.opacity(0.22)
        }
        
        let parameters = [kCIInputImageKey: ciImage]
        guard let filter = CIFilter(name: "CIAreaAverage", parameters: parameters),
              let outputImage = filter.outputImage else {
            return .white.opacity(0.22)
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext()
        
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        
        let color = Color(
            red: Double(bitmap[0]) / 255.0,
            green: Double(bitmap[1]) / 255.0,
            blue: Double(bitmap[2]) / 255.0
        )
        
        return color.opacity(0.28)
    }
}

