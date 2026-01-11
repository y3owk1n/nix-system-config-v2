#!/usr/bin/swift

import Cocoa
import Foundation
import CoreGraphics

// MARK: - Helper Functions

func getFrontmostWindow() -> (center: CGPoint, appName: String)? {
    guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
        return nil
    }

    // Get the first layer 0 window (frontmost normal window)
    for window in windows {
        if let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
           let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
           let x = bounds["X"], let y = bounds["Y"],
           let width = bounds["Width"], let height = bounds["Height"] {

            let ownerName = window[kCGWindowOwnerName as String] as? String ?? "unknown"

            // Calculate center point
            let centerX = x + width / 2
            let centerY = y + height / 2
            let center = CGPoint(x: centerX, y: centerY)

            return (center, ownerName)
        }
    }

    return nil
}

// MARK: - Main

guard let (center, appName) = getFrontmostWindow() else {
    print("Error: Could not find frontmost window")
    exit(1)
}

print("Moving mouse to center of \(appName) window")
print("Position: (\(center.x), \(center.y))")

// Move mouse to center
CGWarpMouseCursorPosition(center)

print("✓ Mouse moved to window center")
