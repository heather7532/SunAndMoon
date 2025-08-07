import Foundation
import CoreGraphics
import CoreLocation
import SwiftUI

/// Renders a moon phase by overlaying a cropped shadow mask onto the full moon image.
/// - Parameters:
///   - latitude: Latitude from GPS
///   - phasePercent: 0.0 to 1.0 (illuminated portion)
///   - moonAge: Moon age in days (0–29.5)
///   - fullMoonCG: Full moon image (CGImage with transparency)
///   - shadowCG: Shadow image (a full circular black disc with slight transparency)
/// - Returns: SwiftUI Image with correct phase rendering
func MoonRendererWatch(
    latitude: CLLocationDegrees,
    phasePercent: CGFloat,
    moonAge: CGFloat,
    fullMoonCG: CGImage,
    shadowCG: CGImage
) -> Image {
    let width = fullMoonCG.width
    let height = fullMoonCG.height
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    debugPrint("[MoonRendererWatch] ---")
    debugPrint("Latitude: \(latitude)")
    debugPrint("Phase Percent: \(String(format: "%.4f", phasePercent))")
    debugPrint("Moon Age: \(String(format: "%.2f", moonAge))")

    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        debugPrint("[MoonRendererWatch] Failed to create CGContext")
        return Image(systemName: "moon.circle.fill")
    }

    let fullRect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(fullMoonCG, in: fullRect)

    // Clamp phasePercent between 0–1
    let clamped = max(0, min(1, phasePercent))

    // Handle new/full moon — skip overlay
    if clamped <= 0.02 || clamped >= 0.98 {
        debugPrint("Phase nearly full or new. Skipping shadow overlay.")
        guard let finalCG = context.makeImage() else {
            return Image(systemName: "moon.circle.fill")
        }
        return Image(decorative: finalCG, scale: 1.0)
            .renderingMode(.original)
            .interpolation(.none)
    }

    // Determine lit side
    let isWaxing = moonAge < 14.77
    let isSouthern = latitude < 0
    let isLeftLit = (isWaxing && !isSouthern) || (!isWaxing && isSouthern)

    let shadowWidth = CGFloat(width) * (1.0 - clamped)
    let cropRect = CGRect(x: 0, y: 0, width: shadowWidth, height: CGFloat(height))  // Always crop from left

    debugPrint("isWaxing: \(isWaxing)")
    debugPrint("isSouthern: \(isSouthern)")
    debugPrint("isLeftLit: \(isLeftLit)")
    debugPrint("Shadow width: \(shadowWidth)")
    debugPrint("Cropping shadow rect: \(cropRect)")

    guard let croppedShadow = shadowCG.cropping(to: cropRect) else {
        debugPrint("[MoonRendererWatch] Failed to crop shadow mask")
        return Image(systemName: "moon.circle.fill")
    }

    // Draw cropped shadow on correct side
    context.saveGState()

    if isLeftLit {
        // Draw on right side
        let destRect = CGRect(x: CGFloat(width) - shadowWidth, y: 0, width: shadowWidth, height: CGFloat(height))
        context.draw(croppedShadow, in: destRect)
    } else {
        // Flip and draw on left side
        context.translateBy(x: shadowWidth, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)
        context.draw(croppedShadow, in: cropRect)
    }

    context.restoreGState()

    guard let finalCG = context.makeImage() else {
        debugPrint("[MoonRendererWatch] Failed to make final image")
        return Image(systemName: "moon.circle.fill")
    }

    return Image(decorative: finalCG, scale: 1.0)
        .renderingMode(.original)
        .interpolation(.none)
}
