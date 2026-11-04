#!/usr/bin/env swift
// Generates the CornerTimer app icon (design spec: issue #13).
// Usage: make-icon.swift <output.iconset directory>
// Only AppKit/CoreGraphics primitives are used: no SF Symbols, fonts or external images.
import AppKit

/// Draws the icon into a square bitmap of `pixels` x `pixels`.
/// Geometry is written in the spec's 1024-point, top-left-origin space and scaled.
func renderIcon(pixels: Int) -> Data? {
    let size = CGFloat(pixels)
    let s = size / 1024
    let small = pixels <= 32  // drop the shadow and thicken the ring so it stays legible
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard let ctx = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
        CGColor(
            colorSpace: space,
            components: [
                CGFloat((hex >> 16) & 0xFF) / 255, CGFloat((hex >> 8) & 0xFF) / 255,
                CGFloat(hex & 0xFF) / 255, alpha,
            ])!
    }
    /// Spec rectangle (top-left origin) to CoreGraphics rectangle (bottom-left origin).
    func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: x * s, y: size - (y + h) * s, width: w * s, height: h * s)
    }

    // Body: 824x824 rounded square with a soft drop shadow, then the gradient fill.
    let body = rect(100, 100, 824, 824)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185 * s, cornerHeight: 185 * s, transform: nil)
    ctx.saveGState()
    if !small {
        ctx.setShadow(offset: CGSize(width: 0, height: -12 * s), blur: 24 * s, color: color(0x000000, alpha: 0.3))
    }
    ctx.addPath(bodyPath)
    ctx.setFillColor(color(0x0A3F4B))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: space, colors: [color(0x127386), color(0x0A3F4B)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(
        gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
    ctx.restoreGState()

    // Progress ring: track plus a white arc from 12 o'clock clockwise 270 degrees, with a knob at its end.
    let center = CGPoint(x: 500 * s, y: size - 480 * s)
    let radius = 240 * s
    let ringWidth = small ? 0.22 * size : 64 * s
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.round)

    ctx.setStrokeColor(color(0x9FE8DA, alpha: 0.3))
    ctx.addArc(center: center, radius: radius, startAngle: 0, endAngle: 2 * .pi, clockwise: false)
    ctx.strokePath()

    let start = CGFloat.pi / 2  // 12 o'clock (CoreGraphics y axis points up)
    let end = start - 1.5 * .pi  // 270 degrees clockwise: 9 o'clock
    ctx.setStrokeColor(color(0xFFFFFF))
    ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: true)
    ctx.strokePath()

    let knobRadius = 48 * s
    let knobCenter = CGPoint(x: center.x + radius * cos(end), y: center.y + radius * sin(end))
    ctx.setFillColor(color(0xFFFFFF))
    ctx.fillEllipse(in: CGRect(x: knobCenter.x - knobRadius, y: knobCenter.y - knobRadius, width: 2 * knobRadius, height: 2 * knobRadius))

    // Corner tab: 210x120, radius 28, 64 px inset from the body's lower-right corner.
    let tab = rect(924 - 64 - 210, 924 - 64 - 120, 210, 120)
    ctx.addPath(CGPath(roundedRect: tab, cornerWidth: 28 * s, cornerHeight: 28 * s, transform: nil))
    ctx.setFillColor(color(0xFFD400))
    ctx.fillPath()

    guard let image = ctx.makeImage() else { return nil }
    return NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
}

guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.iconset>\n".utf8))
    exit(64)
}
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)

do {
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    for base in [16, 32, 128, 256, 512] {
        for scale in [1, 2] {
            let name = "icon_\(base)x\(base)" + (scale == 2 ? "@2x" : "") + ".png"
            guard let png = renderIcon(pixels: base * scale) else {
                FileHandle.standardError.write(Data("failed to render \(name)\n".utf8))
                exit(1)
            }
            try png.write(to: outputDirectory.appendingPathComponent(name))
        }
    }
} catch {
    FileHandle.standardError.write(Data("\(error)\n".utf8))
    exit(1)
}
