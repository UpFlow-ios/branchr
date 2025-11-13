//
//  PolylineGlowLayer.swift
//  branchr
//
//  Created for Phase 35.3 - Rainbow route glow effect
//

import SwiftUI
import MapKit

/**
 * 🌈 Polyline Glow Layer
 *
 * Custom MKPolylineRenderer with animated rainbow gradient.
 * Used for rendering glowing ride routes on the map.
 */
class RainbowPolylineRenderer: MKPolylineRenderer {
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Phase 35.7: Enhanced saturation for more vibrant rainbow
        let baseColors: [UIColor] = [
            .systemRed,
            .systemOrange,
            .systemYellow,
            .systemGreen,
            .systemCyan,
            .systemBlue,
            .systemPurple
        ]
        let colors: [UIColor] = baseColors.map { $0.withAlphaComponent(0.95) }
        
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) else {
            super.draw(mapRect, zoomScale: zoomScale, in: context)
            return
        }
        
        // Save context state
        context.saveGState()
        
        // Set line properties
        context.setLineWidth(lineWidth / zoomScale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw the polyline path
        guard let path = self.path else {
            super.draw(mapRect, zoomScale: zoomScale, in: context)
            return
        }
        context.addPath(path)
        context.replacePathWithStrokedPath()
        context.clip()
        
        // Get the bounding box of the path
        let boundingBox = path.boundingBox
        let startPoint = CGPoint(x: boundingBox.minX, y: boundingBox.minY)
        let endPoint = CGPoint(x: boundingBox.maxX, y: boundingBox.maxY)
        
        // Draw gradient
        context.drawLinearGradient(
            gradient,
            start: startPoint,
            end: endPoint,
            options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
        )
        
        // Restore context
        context.restoreGState()
        
        // Add outer glow effect
        context.saveGState()
        context.setLineWidth((lineWidth + 4) / zoomScale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(self.path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setShadow(offset: .zero, blur: 8, color: UIColor.white.withAlphaComponent(0.5).cgColor)
        context.strokePath()
        context.restoreGState()
    }
}

