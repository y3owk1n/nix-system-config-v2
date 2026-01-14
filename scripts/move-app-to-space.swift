#!/usr/bin/swift

import Cocoa
import Foundation
import CoreGraphics
import ApplicationServices

// MARK: - Helper Functions

// Heuristic detection for standard titlebar windows
func hasStandardTitleBar(pid: pid_t) -> Bool {
    let app = AXUIElementCreateApplication(pid)
    var windowRef: AnyObject?

    // Get the frontmost window
    let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef)

    guard result == .success, let window = windowRef else {
        print("Could not get AX window, defaulting to standard title bar")
        return true // Default to standard if we can't determine
    }

    // Check if window has a close button (standard title bar indicator)
    var value: AnyObject?
    let hasCloseButton = AXUIElementCopyAttributeValue(
        window as! AXUIElement,
        kAXCloseButtonAttribute as CFString,
        &value
    ) == .success

    print("Window has standard title bar controls: \(hasCloseButton)")

    // Terminal apps without standard title bars won't have these standard controls
    return hasCloseButton
}

func isWindowFullscreen(pid: pid_t) -> Bool {
    let app = AXUIElementCreateApplication(pid)
    var windowRef: AnyObject?

    let result = AXUIElementCopyAttributeValue(app, kAXFocusedWindowAttribute as CFString, &windowRef)

    guard result == .success, let window = windowRef else {
        return false
    }

    // Check if window is in fullscreen mode
    var value: AnyObject?
    let hasFullscreenButton = AXUIElementCopyAttributeValue(
        window as! AXUIElement,
        kAXFullScreenButtonAttribute as CFString,
        &value
    ) == .success

    if hasFullscreenButton, let button = value as! AXUIElement? {
        var isFullscreen: AnyObject?
        if AXUIElementCopyAttributeValue(button, "AXSubrole" as CFString, &isFullscreen) == .success {
            // If we can get the subrole, check window's fullscreen state directly
            var fullscreenValue: AnyObject?
            if AXUIElementCopyAttributeValue(window as! AXUIElement, "AXFullScreen" as CFString, &fullscreenValue) == .success {
                return (fullscreenValue as? Bool) ?? false
            }
        }
    }

    return false
}

// Private API declarations for space management
@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> UInt32

@_silgen_name("CGSCopySpaces")
func CGSCopySpaces(_ connection: UInt32, _ selector: Int) -> CFArray?

@_silgen_name("CGSGetActiveSpace")
func CGSGetActiveSpace(_ connection: UInt32) -> UInt64

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: UInt32) -> CFArray?

func getCurrentSpace() -> Int? {
    let connection = CGSMainConnectionID()
    let activeSpaceID = CGSGetActiveSpace(connection)

    // Get all display spaces to map space ID to index
    guard let managedSpaces = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
        return nil
    }

    // Loop through displays and their spaces
    for display in managedSpaces {
        if let spaces = display["Spaces"] as? [[String: Any]] {
            for (index, space) in spaces.enumerated() {
                if let spaceID = space["ManagedSpaceID"] as? UInt64,
                   spaceID == activeSpaceID {
                    return index + 1
                }
            }
        }

        // Also check "Current Spaces" key for active space
        if let currentSpaces = display["Current Space"] as? [String: Any],
           let spaceID = currentSpaces["ManagedSpaceID"] as? UInt64,
           spaceID == activeSpaceID {

            // Find this space's index in the Spaces array
            if let spaces = display["Spaces"] as? [[String: Any]] {
                for (index, space) in spaces.enumerated() {
                    if let sid = space["ManagedSpaceID"] as? UInt64,
                       sid == activeSpaceID {
                        return index + 1
                    }
                }
            }
        }
    }

    return nil
}

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

            // Check if window is fullscreen
            if isWindowFullscreen(pid: pid) {
                print("Error: Window is in fullscreen mode. Cannot move fullscreen windows.")
                print("Please exit fullscreen first (Cmd+Ctrl+F or green button)")
                exit(1)
            }

            // Use AX API to detect if window has standard title bar
            let hasStandardChrome = hasStandardTitleBar(pid: pid)
            let isBorderless = !hasStandardChrome

            let dragPoint: CGPoint

            if isBorderless {
                // For borderless windows, grab the VERY TOP EDGE (1-2 pixels from top)
                print("Detected borderless window - will grab top edge")
                let edgeY = y + 2  // Just 2 pixels down from the absolute top
                let centerX = x + width / 2
                dragPoint = CGPoint(x: centerX, y: edgeY)
            } else {
                // For normal windows with title bar, grab near the window controls
                print("Detected standard window with title bar")
                let titleBarY = y + 2
                let titleBarX = x + 100  // To the right of close/minimize/maximize buttons
                dragPoint = CGPoint(x: titleBarX, y: titleBarY)
            }

            print("Drag point: (\(dragPoint.x), \(dragPoint.y))")

            return (pid, dragPoint, ownerName)
        }
    }

    return nil
}

func simulateDragAndMove(titleBarPos: CGPoint, targetSpace: Int, pid: pid_t) {
    // Save the current mouse position
    let savedPos = NSEvent.mouseLocation

    defer {
        // Restore the original position (defer after everything else finishes)
        CGWarpMouseCursorPosition(savedPos)
    }

    print("Simulating drag at position: (\(titleBarPos.x), \(titleBarPos.y))")

    let isBorderless = !hasStandardTitleBar(pid: pid)

    // Move mouse to drag position
    CGWarpMouseCursorPosition(titleBarPos)
    usleep(30_000)

    // Press and hold mouse button (start dragging)
    let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown,
                           mouseCursorPosition: titleBarPos, mouseButton: .left)
    mouseDown?.post(tap: .cghidEventTap)

    if isBorderless {
        print("Started dragging borderless window from top edge...")
    } else {
        print("Started dragging window from title bar...")
    }

    usleep(60_000) // wait for drag to register

    // Move mouse slightly to initiate and confirm drag
    let dragPos = CGPoint(x: titleBarPos.x + 5, y: titleBarPos.y + 5)
    let mouseDrag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged,
                           mouseCursorPosition: dragPos, mouseButton: .left)
    mouseDrag?.post(tap: .cghidEventTap)
    usleep(30_000) // wait ...

    // While still holding mouse, trigger space switch
    print("Switching to space \(targetSpace) while dragging...")

    // NOTE: These are keycodes for 1 - 9
    // If you have different shortcuts, change these to your respective keycodes
    let keyCodes: [Int: CGKeyCode] = [1: 18, 2: 19, 3: 20, 4: 21, 5: 22, 6: 23, 7: 24, 8: 25, 9: 26]

    if let keyCode = keyCodes[targetSpace] {
        // Press Command+Shift+Control+Option + Number
        let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        // NOTE: Change these flags to match your keyboard shortcuts
        keyDown?.flags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]
        keyDown?.post(tap: .cghidEventTap)
        usleep(10_000) // minimal delay between key down/up

        let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        keyUp?.post(tap: .cghidEventTap)
        usleep(200_000) // wait for space switch animation
    } else {
        print("Error: Only spaces 1-9 are supported with this method")
        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                             mouseCursorPosition: dragPos, mouseButton: .left)
        mouseUp?.post(tap: .cghidEventTap)
        return
    }

    // Release mouse button (drop window)
    let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp,
                         mouseCursorPosition: dragPos, mouseButton: .left)
    mouseUp?.post(tap: .cghidEventTap)
    print("Released window")

    usleep(50_000) // wait for drop to complete

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
    print("4. Grant Accessibility permissions when prompted")
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

guard let (pid, titleBarPos, appName) = getFrontmostWindow() else {
    print("Error: Could not find frontmost window")
    exit(1)
}

// Check if we're already on the target space
if let currentSpace = getCurrentSpace() {
    print("Current space: \(currentSpace)")
    if currentSpace == targetSpace {
        print("Error: Window is already on Space \(targetSpace)")
        print("Nothing to do!")
        exit(0)
    }
} else {
    print("Warning: Could not determine current space, proceeding anyway...")
}

print("Moving window: \(appName)")
simulateDragAndMove(titleBarPos: titleBarPos, targetSpace: targetSpace, pid: pid)

print("✓ Done! Check if your window moved to Space \(targetSpace)")
