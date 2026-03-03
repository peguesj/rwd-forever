#!/usr/bin/env swift
// Generate GitHub social preview image (1280x640)
// SPDX-License-Identifier: MIT

import AppKit
import Foundation

let width: CGFloat = 1280
let height: CGFloat = 640

guard CommandLine.arguments.count >= 2 else {
    print("Usage: gen-social.swift <output-path>")
    exit(1)
}
let outputPath = CommandLine.arguments[1]

let image = NSImage(size: NSSize(width: width, height: height))
image.lockFocus()

let ctx = NSGraphicsContext.current!.cgContext
let colorSpace = CGColorSpaceCreateDeviceRGB()

// Background gradient
let bgColors = [
    CGColor(colorSpace: colorSpace, components: [0.04, 0.04, 0.08, 1.0])!,
    CGColor(colorSpace: colorSpace, components: [0.10, 0.06, 0.18, 1.0])!,
    CGColor(colorSpace: colorSpace, components: [0.04, 0.04, 0.08, 1.0])!,
] as CFArray
let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 0.5, 1])!
ctx.drawLinearGradient(bgGradient,
                       start: CGPoint(x: 0, y: height),
                       end: CGPoint(x: width, y: 0),
                       options: [])

// Radial glow
let glowColors = [
    CGColor(colorSpace: colorSpace, components: [0.18, 0.10, 0.35, 0.35])!,
    CGColor(colorSpace: colorSpace, components: [0.18, 0.10, 0.35, 0.0])!,
] as CFArray
let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0, 1])!
ctx.drawRadialGradient(glowGradient,
                       startCenter: CGPoint(x: width / 2, y: height / 2),
                       startRadius: 0,
                       endCenter: CGPoint(x: width / 2, y: height / 2),
                       endRadius: width * 0.45,
                       options: [])

// Title
let titleFont = NSFont.systemFont(ofSize: 96, weight: .heavy)
let titleAttrs: [NSAttributedString.Key: Any] = [
    .font: titleFont,
    .foregroundColor: NSColor.white,
]
let title = "RWD4EVR" as NSString
let titleSize = title.size(withAttributes: titleAttrs)
title.draw(at: NSPoint(x: (width - titleSize.width) / 2, y: height / 2 - 10),
           withAttributes: titleAttrs)

// Subtitle
let subFont = NSFont.systemFont(ofSize: 28, weight: .medium)
let subAttrs: [NSAttributedString.Key: Any] = [
    .font: subFont,
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.55),
]
let subtitle = "Rewind.app Lives Forever" as NSString
let subSize = subtitle.size(withAttributes: subAttrs)
subtitle.draw(at: NSPoint(x: (width - subSize.width) / 2, y: height / 2 - 55),
              withAttributes: subAttrs)

// Tag line
let tagFont = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
let tagAttrs: [NSAttributedString.Key: Any] = [
    .font: tagFont,
    .foregroundColor: NSColor(calibratedRed: 0.4, green: 0.6, blue: 1.0, alpha: 0.6),
]
let tagline = "ARM64 binary patch \u{2022} 8 bytes \u{2022} 19 bypass points" as NSString
let tagSize = tagline.size(withAttributes: tagAttrs)
tagline.draw(at: NSPoint(x: (width - tagSize.width) / 2, y: height / 2 - 95),
             withAttributes: tagAttrs)

// Infinity symbol
let symFont = NSFont.systemFont(ofSize: 36, weight: .ultraLight)
let symAttrs: [NSAttributedString.Key: Any] = [
    .font: symFont,
    .foregroundColor: NSColor(calibratedWhite: 1.0, alpha: 0.3),
]
let sym = "\u{221E}" as NSString
let symSize = sym.size(withAttributes: symAttrs)
sym.draw(at: NSPoint(x: (width - symSize.width) / 2, y: height / 2 + 100),
         withAttributes: symAttrs)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to render social image")
    exit(1)
}

try! png.write(to: URL(fileURLWithPath: outputPath))
print("  Social preview: \(outputPath) (\(Int(width))x\(Int(height)))")
