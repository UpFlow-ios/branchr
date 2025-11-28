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
        // VIBRANT rainbow colors for the route polyline (not pastel)
        let vibrantRainbowColors: [UIColor] = [
            UIColor(red: 1.00, green: 0.15, blue: 0.35, alpha: 1.0), // hot pink / red
            UIColor(red: 1.00, green: 0.55, blue: 0.00, alpha: 1.0), // orange
            UIColor(red: 1.00, green: 0.92, blue: 0.00, alpha: 1.0), // bright yellow
            UIColor(red: 0.00, green: 0.85, blue: 0.35, alpha: 1.0), // bright green
            UIColor(red: 0.00, green: 0.45, blue: 1.00, alpha: 1.0), // strong blue
            UIColor(red: 0.55, green: 0.20, blue: 1.00, alpha: 1.0)  // purple
        ]
        let colors = vibrantRainbowColors
        
        // Create gradient
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map { $0.cgColor } as CFArray
        guard let gradient = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: nil) else {
            super.draw(mapRect, zoomScale: zoomScale, in: context)
            return
        }
        
        // Ensure we have a path before touching the context state
        guard let path = self.path else {
            super.draw(mapRect, zoomScale: zoomScale, in: context)
            return
        }
        
        // Save context state for primary gradient stroke
        context.saveGState()
        defer { context.restoreGState() }
        
        // Set line properties
        context.setLineWidth(lineWidth / zoomScale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw the polyline path
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
        
        // Add outer glow effect
        context.saveGState()
        context.setLineWidth((lineWidth + 4) / zoomScale)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addPath(path)
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
        context.setShadow(offset: .zero, blur: 8, color: UIColor.white.withAlphaComponent(0.5).cgColor)
        context.strokePath()
        context.restoreGState()
    }
}

