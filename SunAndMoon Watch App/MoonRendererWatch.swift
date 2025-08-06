import Foundation
import CoreGraphics
import CoreLocation
import SwiftUI

/// Renders a moon phase as a SwiftUI Image for watchOS using Core Graphics.
///
/// - Parameters:
///   - latitude: Latitude from GPS
///   - phasePercent: 0.0 to 1.0 (illuminated portion)
///   - moonAge: Moon age in days (0–29.5)
///   - fullMoonCG: CGImage of the full moon texture (with transparency)
/// - Returns: SwiftUI Image rendered with proper masking
func MoonRendererWatch(
    latitude: CLLocationDegrees,
    phasePercent: CGFloat,
    moonAge: CGFloat,
    fullMoonCG: CGImage
) -> Image {
    
    let width = fullMoonCG.width
    let height = fullMoonCG.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        return Image(systemName: "moon.circle.fill")
    }

    // Draw the full moon base image
    context.draw(fullMoonCG, in: CGRect(x: 0, y: 0, width: width, height: height))

    // Determine masking direction
    let isWaxing = moonAge < 14.77
    let isSouthern = latitude < 0
    let isRightLit = (isWaxing && !isSouthern) || (!isWaxing && isSouthern)

    let shadowAmount = 1.0 - max(0, min(1, phasePercent))
    let shadowOffset = CGFloat(shadowAmount) * CGFloat(width) / 2.0

    // Configure shadow ellipse
    let shadowRect: CGRect
    if isRightLit {
        shadowRect = CGRect(x: CGFloat(width) / 2 - shadowOffset, y: 0, width: CGFloat(width), height: CGFloat(height))
    } else {
        shadowRect = CGRect(x: 0, y: 0, width: CGFloat(width) / 2 + shadowOffset, height: CGFloat(height))
    }

    context.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
    context.setBlendMode(.sourceAtop)
    context.fillEllipse(in: shadowRect)

    guard let maskedCGImage = context.makeImage() else {
        return Image(systemName: "moon.circle.fill")
    }

    return Image(decorative: maskedCGImage, scale: 1.0)
}//
//  MoonRendererWatch.swift
//  SunAndMoon
//
//  Created by Heather Gulledge on 8/6/25.
//

