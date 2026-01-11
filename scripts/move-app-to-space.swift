#!/usr/bin/swift

import Cocoa
import Foundation
import CoreGraphics

// MARK: - Helper Functions

func getFrontmostWindow() -> (pid: pid_t, position: CGPoint, appName: String)? {
    guard let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
        return nil
    }

    // Get the first layer 0 window (frontmost normal window)
    for window in windows {
        if let layer = window[kCGWindowLayer as String] as? Int, layer == 0,
           let pid = window[kCGWindowOwnerPID as String] as? pid_t,
           let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
           let x = bounds["X"], let y = bounds["Y"],
           let width = bounds["Width"], let height = bounds["Height"] {

            let ownerName = window[kCGWindowOwnerName as String] as? String ?? "unknown"
            print("Found window: \(ownerName)")
            print("Window bounds: x=\(x), y=\(y), width=\(width), height=\(height)")

            // Apps known to be borderless/without title bars
            let borderlessApps = ["Alacritty", "alacritty", "Ghostty", "ghostty", "kitty", "Kitty"]
            let isBorderless = borderlessApps.contains { ownerName.lowercased().contains($0.lowercased()) }

            let dragPoint: CGPoint

            if isBorderless {
                // For borderless windows, grab the VERY TOP EDGE (1-2 pixels from top)
                print("Detected borderless window - will grab top edge")
                let edgeY = y + 2  // Just 2 pixels down from the absolute top
                let centerX = x + width / 2
                dragPoint = CGPoint(x: centerX, y: edgeY)
            } else {
                // For normal windows with title bar, grab near the window controls
                // The close button is typically at x+10-20, so grab to the right of it
                // Title bar is usually 22-28px tall on modern macOS
                let titleBarY = y + 2  // Middle of the title bar (around 11px from top)
                let titleBarX = x + 100  // To the right of close/minimize/maximize buttons
                dragPoint = CGPoint(x: titleBarX, y: titleBarY)
            }

            print("Drag point: (\(dragPoint.x), \(dragPoint.y))")

            return (pid, dragPoint, ownerName)
        }
    }

    return nil
}

func simulateDragAndMove(titleBarPos: CGPoint, targetSpace: Int, appName: String) {
    print("Simulating drag at position: (\(titleBarPos.x), \(titleBarPos.y))")

    // Check if this is a borderless app
    let borderlessApps = ["Alacritty", "alacritty", "Ghostty", "ghostty", "kitty", "Kitty"]
    let isBorderless = borderlessApps.contains { appName.lowercased().contains($0.lowercased()) }

    // Step 1: Move mouse to drag position
    CGWarpMouseCursorPosition(titleBarPos)
    usleep(150_000) // 0.15 second - give it a bit more time to position

    // Step 2: Press and hold mouse button (start dragging)
    // No modifier keys needed - just grab the top edge directly
    let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                           mouseCursorPosition: titleBarPos, mouseButton: .left)
    mouseDown?.post(tap: .cghidEventTap)

    if isBorderless {
        print("Started dragging borderless window from top edge...")
    } else {
        print("Started dragging window from title bar...")
    }

    usleep(250_000) // 0.25 second - longer wait to ensure drag starts

    // Step 3: Move mouse slightly to initiate and confirm drag
    let dragPos = CGPoint(x: titleBarPos.x + 10, y: titleBarPos.y + 5)
    let mouseDrag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged,
                           mouseCursorPosition: dragPos, mouseButton: .left)
    mouseDrag?.post(tap: .cghidEventTap)
    usleep(150_000) // 0.15 second

    // Step 4: While still holding mouse, trigger space switch
    print("Switching to space \(targetSpace) while dragging...")

    // Use Command+Shift+Control+Option + Number to switch spaces
    let keyCodes: [Int: CGKeyCode] = [1: 18, 2: 19, 3: 20, 4: 21, 5: 22, 6: 23, 7: 24, 8: 25, 9: 26]

    if let keyCode = keyCodes[targetSpace] {
        // Press Command+Shift+Control+Option + Number
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]
        keyDown?.post(tap: .cghidEventTap)
        usleep(50_000)

        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)
        usleep(400_000) // Longer wait for space switch animation
    } else {
        print("Error: Only spaces 1-9 are supported with this method")
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                             mouseCursorPosition: dragPos, mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
        return
    }

    // Step 5: Release mouse button (drop window)
    let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                         mouseCursorPosition: dragPos, mouseButton: .left)
    mouseUp?.post(tap: .cghidEventTap)
    print("Released window")

    usleep(300_000) // 0.3 second for drop animation

    print("✓ Window should now be on Space \(targetSpace)")
}

// MARK: - Main

func printUsage() {
    print("Usage: move-window-to-space <space_number>")
    print("Example: move-window-to-space 2")
    print("\nREQUIREMENTS:")
    print("1. System Settings → Keyboard → Keyboard Shortcuts → Mission Control")
    print("2. Enable 'Switch to Desktop 1', 'Switch to Desktop 2', etc.")
    print("3. Set shortcuts to Cmd+Shift+Ctrl+Opt+1, Cmd+Shift+Ctrl+Opt+2, etc.")
    print("\nNOTE: This works by simulating a drag operation, so don't move your")
    print("      mouse while it's running!")
}

let args = CommandLine.arguments
if args.count < 2 {
    printUsage()
    exit(1)
}

guard let targetSpace = Int(args[1]) else {
    print("Error: Space number must be an integer")
    printUsage()
    exit(1)
}

if targetSpace < 1 || targetSpace > 9 {
    print("Error: Space number must be between 1 and 9")
    exit(1)
}

guard let (_, titleBarPos, appName) = getFrontmostWindow() else {
    print("Error: Could not find frontmost window")
    exit(1)
}

print("\nIMPORTANT: Do not move your mouse for the next 2 seconds!")
usleep(500_000) // Give user time to read the message

simulateDragAndMove(titleBarPos: titleBarPos, targetSpace: targetSpace, appName: appName)

print("\n✓ Done! Check if your window moved to Space \(targetSpace)")
