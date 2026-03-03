#!/usr/bin/env swift
// Generate app icon PNGs for RWD4EVR
// SPDX-License-Identifier: MIT

import AppKit
import Foundation

let sizes: [(String, Int, Int)] = [
    ("icon_16x16",      16,  1),
    ("icon_16x16@2x",   16,  2),
    ("icon_32x32",      32,  1),
    ("icon_32x32@2x",   32,  2),
    ("icon_128x128",    128, 1),
    ("icon_128x128@2x", 128, 2),
    ("icon_256x256",    256, 1),
    ("icon_256x256@2x", 256, 2),
    ("icon_512x512",    512, 1),
    ("icon_512x512@2x", 512, 2),
]

guard CommandLine.arguments.count >= 2 else {
    print("Usage: gen-icon.swift <output-dir> [variant]")
    exit(1)
}

let outputDir = CommandLine.arguments[1]
let variant = CommandLine.arguments.count >= 3 ? CommandLine.arguments[2] : "Installer"
let isInstaller = variant.contains("Installer")

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext

    // Background: rounded rect
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let path = CGPath(roundedRect: rect.insetBy(dx: size * 0.02, dy: size * 0.02),
                      cornerWidth: cornerRadius, cornerHeight: cornerRadius,
                      transform: nil)

    // Gradient background
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    if isInstaller {
        // Deep blue to purple gradient
        let colors = [
            CGColor(colorSpace: colorSpace, components: [0.08, 0.08, 0.20, 1.0])!,
            CGColor(colorSpace: colorSpace, components: [0.15, 0.05, 0.30, 1.0])!,
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: size),
                               end: CGPoint(x: size, y: 0),
                               options: [])
        ctx.resetClip()
    } else {
        // Dark red gradient for uninstaller
        let colors = [
            CGColor(colorSpace: colorSpace, components: [0.20, 0.08, 0.08, 1.0])!,
            CGColor(colorSpace: colorSpace, components: [0.30, 0.05, 0.10, 1.0])!,
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
        ctx.addPath(path)
        ctx.clip()
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: size),
                               end: CGPoint(x: size, y: 0),
                               options: [])
        ctx.resetClip()
    }

    // Draw border
    ctx.addPath(path)
    ctx.setStrokeColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.15])!)
    ctx.setLineWidth(size * 0.01)
    ctx.strokePath()

    // Draw "RWD" text
    let fontSize = size * 0.28
    let font = NSFont.systemFont(ofSize: fontSize, weight: .heavy)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let text = "RWD" as NSString
    let textSize = text.size(withAttributes: attrs)
    let textX = (size - textSize.width) / 2
    let textY = size * 0.42
    text.draw(at: NSPoint(x: textX, y: textY), withAttributes: attrs)

    // Draw "4EVR" text below
    let smallSize = size * 0.18
    let smallFont = NSFont.systemFont(ofSize: smallSize, weight: .bold)
    let tintColor: NSColor = isInstaller
        ? NSColor(calibratedRed: 0.4, green: 0.6, blue: 1.0, alpha: 1.0)
        : NSColor(calibratedRed: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
    let smallAttrs: [NSAttributedString.Key: Any] = [
        .font: smallFont,
        .foregroundColor: tintColor,
    ]
    let smallText = "4EVR" as NSString
    let smallTextSize = smallText.size(withAttributes: smallAttrs)
    let smallX = (size - smallTextSize.width) / 2
    let smallY = size * 0.22
    smallText.draw(at: NSPoint(x: smallX, y: smallY), withAttributes: smallAttrs)

    // Draw infinity symbol at top
    let symSize = size * 0.12
    let symFont = NSFont.systemFont(ofSize: symSize, weight: .ultraLight)
    let symAttrs: [NSAttributedString.Key: Any] = [
        .font: symFont,
        .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.5),
    ]
    let sym = "\u{221E}" as NSString
    let symTextSize = sym.size(withAttributes: symAttrs)
    let symX = (size - symTextSize.width) / 2
    let symY = size * 0.68
    sym.draw(at: NSPoint(x: symX, y: symY), withAttributes: symAttrs)

    image.unlockFocus()
    return image
}

for (name, baseSize, scale) in sizes {
    let pixelSize = CGFloat(baseSize * scale)
    let image = drawIcon(size: pixelSize)

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create \(name)")
        continue
    }

    let path = "\(outputDir)/\(name).png"
    try! png.write(to: URL(fileURLWithPath: path))
}

print("  Icons generated in \(outputDir)/")
