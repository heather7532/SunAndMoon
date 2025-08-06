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

    debugPrint("[MoonRendererWatch] ---")
    debugPrint("Latitude: \(latitude)")
    debugPrint("Phase Percent: \(String(format: "%.4f", phasePercent))")
    debugPrint("Moon Age: \(String(format: "%.2f", moonAge))")
    debugPrint("Full Moon Image Size: \(width)x\(height)")

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

    // Draw full moon base
    let drawRect = CGRect(x: 0, y: 0, width: width, height: height)
    context.draw(fullMoonCG, in: drawRect)

    // Determine direction
    let isWaxing = moonAge < 14.77
    let isSouthern = latitude < 0
    let isRightLit = (isWaxing && !isSouthern) || (!isWaxing && isSouthern)

    // Shadow math
    let clampedPercent = max(0, min(1, phasePercent))
    let shadowAmount = pow(1.0 - clampedPercent, 1.5)
    let offset = CGFloat(shadowAmount) * CGFloat(width) / 2.0

    debugPrint("Clamped Phase Percent: \(String(format: "%.4f", clampedPercent))")
    debugPrint("Shadow Amount: \(String(format: "%.4f", shadowAmount))")
    debugPrint("Offset: \(String(format: "%.2f", offset))")
    debugPrint("isRightLit: \(isRightLit)")

    // Slide the shadow ellipse
    let ellipseWidth = CGFloat(width)
    let ellipseHeight = CGFloat(height)
    let shadowRect: CGRect

    if isRightLit {
        // Shadow slides left
        shadowRect = CGRect(
            x: (CGFloat(width) / 2) - offset,
            y: 0,
            width: ellipseWidth,
            height: ellipseHeight
        )
    } else {
        // Shadow slides right
        shadowRect = CGRect(
            x: (CGFloat(width) / 2) + offset - ellipseWidth,
            y: 0,
            width: ellipseWidth,
            height: ellipseHeight
        )
    }

    debugPrint("Shadow Rect: \(shadowRect)")

    if clampedPercent < 0.999 {
        context.setBlendMode(.destinationOut)
        context.setFillColor(CGColor(gray: 0.0, alpha: 1.0))
        context.fillEllipse(in: shadowRect)
        debugPrint("Applied shadow ellipse with destinationOut blend mode")
    } else {
        debugPrint("Phase is effectively full; skipping shadow ellipse")
    }

    guard let maskedCGImage = context.makeImage() else {
        debugPrint("[MoonRendererWatch] Failed to create masked CGImage")
        return Image(systemName: "moon.circle.fill")
    }

    return Image(decorative: maskedCGImage, scale: 1.0)
        .renderingMode(.original)
        .interpolation(.none)
}
