#!/usr/bin/env swift
// Generate DMG background image for RWD4EVR
// SPDX-License-Identifier: MIT

import AppKit
import Foundation

let width: CGFloat = 660
let height: CGFloat = 450

guard CommandLine.arguments.count >= 2 else {
    print("Usage: gen-background.swift <output-path>")
    exit(1)
}
let outputPath = CommandLine.arguments[1]

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext
let colorSpace = CGColorSpaceCreateDeviceRGB()

// Background gradient: deep dark blue-black
let bgColors = [
    CGColor(colorSpace: colorSpace, components: [0.04, 0.04, 0.08, 1.0])!,
    CGColor(colorSpace: colorSpace, components: [0.08, 0.06, 0.14, 1.0])!,
    CGColor(colorSpace: colorSpace, components: [0.04, 0.04, 0.08, 1.0])!,
] as CFArray
let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 0.5, 1])!
ctx.drawLinearGradient(bgGradient,
                       start: CGPoint(x: 0, y: height),
                       end: CGPoint(x: width, y: 0),
                       options: [])

// Subtle radial glow in center
let glowColors = [
    CGColor(colorSpace: colorSpace, components: [0.15, 0.10, 0.30, 0.3])!,
    CGColor(colorSpace: colorSpace, components: [0.15, 0.10, 0.30, 0.0])!,
] as CFArray
let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1])!
ctx.drawRadialGradient(glowGradient,
                       startCenter: CGPoint(x: width / 2, y: height * 0.65),
                       startRadius: 0,
                       endCenter: CGPoint(x: width / 2, y: height * 0.65),
                       endRadius: width * 0.5,
                       options: [])

// Title: "RWD4EVR"
let titleSize: CGFloat = 52
let titleFont = NSFont.systemFont(ofSize: titleSize, weight: .heavy)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor.white,
]
let title = "RWD4EVR" as NSString
let titleTextSize = title.size(withAttributes: titleAttrs)
let titleX = (width - titleTextSize.width) / 2
let titleY = height - 85
title.draw(at: NSPoint(x: titleX, y: titleY), withAttributes: titleAttrs)

// Subtitle
let subSize: CGFloat = 14
let subFont = NSFont.systemFont(ofSize: subSize, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.5),
]
let subtitle = "Rewind.app Lives Forever" as NSString
let subTextSize = subtitle.size(withAttributes: subAttrs)
let subX = (width - subTextSize.width) / 2
let subY = height - 112
subtitle.draw(at: NSPoint(x: subX, y: subY), withAttributes: subAttrs)

// Thin separator line
ctx.setStrokeColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.1])!)
ctx.setLineWidth(0.5)
ctx.move(to: CGPoint(x: width * 0.15, y: height - 125))
ctx.addLine(to: CGPoint(x: width * 0.85, y: height - 125))
ctx.strokePath()

// Icon drop zone labels (positioned where icons will sit)
let labelFont = NSFont.systemFont(ofSize: 11, weight: .medium)
let labelAttrs: [NSAttributedString.Key: Any] = [
    .font: labelFont,
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.35),
]

// Installer label (left side)
let installLabel = "Install" as NSString
let installLabelSize = installLabel.size(withAttributes: labelAttrs)
installLabel.draw(at: NSPoint(x: 165 - installLabelSize.width / 2, y: 55),
                  withAttributes: labelAttrs)

// Uninstaller label (center)
let uninstallLabel = "Uninstall" as NSString
let uninstallLabelSize = uninstallLabel.size(withAttributes: labelAttrs)
uninstallLabel.draw(at: NSPoint(x: width / 2 - uninstallLabelSize.width / 2, y: 55),
                    withAttributes: labelAttrs)

// README label (right side)
let readmeLabel = "README" as NSString
let readmeLabelSize = readmeLabel.size(withAttributes: labelAttrs)
readmeLabel.draw(at: NSPoint(x: 495 - readmeLabelSize.width / 2, y: 55),
                 withAttributes: labelAttrs)

// Version info at bottom
let verFont = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
let verAttrs: [NSAttributedString.Key: Any] = [
    .font: verFont,
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.2),
]
let version = "v1.0.0 \u{2022} ARM64 \u{2022} Rewind v1.5607" as NSString
let verSize = version.size(withAttributes: verAttrs)
version.draw(at: NSPoint(x: (width - verSize.width) / 2, y: 15),
             withAttributes: verAttrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to render background")
    exit(1)
}

try! png.write(to: URL(fileURLWithPath: outputPath))
print("  Background: \(outputPath) (\(Int(width))x\(Int(height)))")
