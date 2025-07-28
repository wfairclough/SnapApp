//
//  GlobalHotkeyManager.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-28.
//

import Foundation
import AppKit
import Carbon.HIToolbox

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    
    private var registeredHotkeys: [UInt32: Shortcut] = [:]
    private var hotkeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var nextHotkeyID: UInt32 = 1
    
    private init() {
        AppLogger.shared.info("GlobalHotkeyManager initialized")
    }
    
    func registerHotkey(_ shortcut: Shortcut) -> Bool {
        guard shortcut.isEnabled else {
            AppLogger.shared.info("Skipping disabled shortcut: \(shortcut.name)")
            return false
        }
        
        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1
        
        // Convert NSEvent.ModifierFlags to Carbon modifiers
        var carbonModifiers: UInt32 = 0
        
        if shortcut.modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if shortcut.modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if shortcut.modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if shortcut.modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        
        // Get the correct virtual key code for Carbon Event Manager
        let virtualKeyCode = getVirtualKeyCode(for: shortcut.keyCode, modifierFlags: shortcut.modifierFlags)
        
        AppLogger.shared.info("Registering hotkey: \(shortcut.name), originalKeyCode: \(shortcut.keyCode), virtualKeyCode: \(virtualKeyCode), carbonModifiers: \(carbonModifiers), display: \(shortcut.displayString)")
        print("DEBUG: GlobalHotkeyManager registering - originalKeyCode: \(shortcut.keyCode), virtualKeyCode: \(virtualKeyCode), carbonModifiers: \(carbonModifiers), name: \(shortcut.name)")
        
        // Install event handler if not already installed
        installEventHandlerIfNeeded()
        
        var hotkeyRef: EventHotKeyRef?
        let result = RegisterEventHotKey(
            UInt32(virtualKeyCode),
            carbonModifiers,
            EventHotKeyID(signature: OSType(hotkeyID), id: hotkeyID),
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if result == noErr {
            registeredHotkeys[hotkeyID] = shortcut
            if let ref = hotkeyRef {
                hotkeyRefs[hotkeyID] = ref
            }
            AppLogger.shared.info("Successfully registered hotkey: \(shortcut.name) with ID \(hotkeyID)")
            return true
        } else {
            AppLogger.shared.error("Failed to register hotkey: \(shortcut.name), error: \(result)")
            return false
        }
    }
    
    private func getVirtualKeyCode(for keyCode: Int, modifierFlags: NSEvent.ModifierFlags) -> Int {
        // For letter keys with shift modifier, we need to ensure we're using the base virtual key code
        // Carbon Event Manager expects virtual key codes, not character codes
        
        // Common letter key mappings (these are virtual key codes that work with Carbon)
        switch keyCode {
        case 0: return 0    // A
        case 1: return 1    // S
        case 2: return 2    // D
        case 3: return 3    // F
        case 4: return 4    // H
        case 5: return 5    // G
        case 6: return 6    // Z
        case 7: return 7    // X
        case 8: return 8    // C
        case 9: return 9    // V
        case 11: return 11  // B
        case 12: return 12  // Q
        case 13: return 13  // W
        case 14: return 14  // E
        case 15: return 15  // R
        case 16: return 16  // Y
        case 17: return 17  // T
        case 31: return 31  // O
        case 32: return 32  // U
        case 34: return 34  // I
        case 35: return 35  // P
        case 37: return 37  // L
        case 38: return 38  // J
        case 40: return 40  // K
        case 45: return 45  // N
        case 46: return 46  // M
        
        // Number keys
        case 18: return 18  // 1
        case 19: return 19  // 2
        case 20: return 20  // 3
        case 21: return 21  // 4
        case 22: return 22  // 6
        case 23: return 23  // 5
        case 25: return 25  // 9
        case 26: return 26  // 7
        case 28: return 28  // 8
        case 29: return 29  // 0
        
        // Function keys
        case 122: return 122 // F1
        case 120: return 120 // F2
        case 99: return 99   // F3
        case 118: return 118 // F4
        case 96: return 96   // F5
        case 97: return 97   // F6
        case 98: return 98   // F7
        case 100: return 100 // F8
        case 101: return 101 // F9
        case 109: return 109 // F10
        case 103: return 103 // F11
        case 111: return 111 // F12
        
        // Special keys
        case 36: return 36   // Return
        case 48: return 48   // Tab
        case 49: return 49   // Space
        case 51: return 51   // Delete
        case 53: return 53   // Escape
        
        default:
            // For other keys, return the original keyCode
            return keyCode
        }
    }
    
    func unregisterHotkey(_ shortcut: Shortcut) {
        // Find and remove the hotkey
        for (hotkeyID, registeredShortcut) in registeredHotkeys {
            if registeredShortcut.id == shortcut.id {
                // Unregister the actual hotkey with Carbon
                if let hotkeyRef = hotkeyRefs[hotkeyID] {
                    let result = UnregisterEventHotKey(hotkeyRef)
                    if result == noErr {
                        AppLogger.shared.info("Successfully unregistered Carbon hotkey: \(shortcut.name)")
                    } else {
                        AppLogger.shared.warning("Failed to unregister Carbon hotkey: \(shortcut.name), error: \(result)")
                    }
                }
                
                // Remove from our tracking
                registeredHotkeys.removeValue(forKey: hotkeyID)
                hotkeyRefs.removeValue(forKey: hotkeyID)
                AppLogger.shared.info("Unregistered hotkey: \(shortcut.name)")
                break
            }
        }
    }
    
    func unregisterAllHotkeys() {
        AppLogger.shared.info("Unregistering all hotkeys...")
        
        for (hotkeyID, shortcut) in registeredHotkeys {
            // Unregister the actual hotkey with Carbon
            if let hotkeyRef = hotkeyRefs[hotkeyID] {
                let result = UnregisterEventHotKey(hotkeyRef)
                if result == noErr {
                    AppLogger.shared.info("Successfully unregistered Carbon hotkey: \(shortcut.name)")
                } else {
                    AppLogger.shared.warning("Failed to unregister Carbon hotkey: \(shortcut.name), error: \(result)")
                }
            }
            AppLogger.shared.info("Unregistered hotkey: \(shortcut.name)")
        }
        
        registeredHotkeys.removeAll()
        hotkeyRefs.removeAll()
        AppLogger.shared.info("All hotkeys unregistered")
    }
    
    func reregisterAllHotkeys() {
        AppLogger.shared.info("Re-registering all hotkeys...")
        unregisterAllHotkeys()
        
        // Get current shortcuts from ShortcutManager
        let shortcuts = ShortcutManager.shared.shortcuts
        for shortcut in shortcuts {
            if shortcut.isEnabled {
                _ = registerHotkey(shortcut)
            }
        }
    }
    
    private var eventHandlerInstalled = false
    
    private func installEventHandlerIfNeeded() {
        guard !eventHandlerInstalled else { return }
        
        let eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )
        
        let callback: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            return GlobalHotkeyManager.shared.handleHotkeyEvent(theEvent)
        }
        
        var eventHandler: EventHandlerRef?
        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            callback,
            1,
            [eventSpec],
            nil,
            &eventHandler
        )
        
        if result == noErr {
            eventHandlerInstalled = true
            AppLogger.shared.info("Event handler installed successfully")
        } else {
            AppLogger.shared.error("Failed to install event handler: \(result)")
        }
    }
    
    private func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }
        
        var hotkeyID = EventHotKeyID()
        let result = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotkeyID
        )
        
        if result == noErr {
            let id = hotkeyID.id
            
            if let shortcut = registeredHotkeys[id] {
                AppLogger.shared.info("Hotkey triggered: \(shortcut.name)")
                print("DEBUG: Hotkey triggered - id: \(id), name: \(shortcut.name), keyCode: \(shortcut.keyCode)")
                
                // Execute the shortcut on the main thread
                DispatchQueue.main.async {
                    ShortcutManager.shared.executeShortcut(withId: shortcut.id)
                }
                
                return noErr
            } else {
                print("DEBUG: Hotkey triggered but no shortcut found for id: \(id)")
            }
        }
        
        return OSStatus(eventNotHandledErr)
    }
    
    func checkAccessibilityPermissions() -> Bool {
        // First check if we already have permission
        let isTrusted = AXIsProcessTrusted()
        
        if !isTrusted {
            // Try to register a dummy hotkey to trigger the permission dialog
            // This will make the app appear in System Settings accessibility list
            let result = RegisterEventHotKey(
                UInt32(0), // A key (we won't actually use this)
                UInt32(cmdKey | shiftKey | controlKey | optionKey), // All modifiers
                EventHotKeyID(signature: OSType(999999), id: 999999), // Dummy ID
                GetApplicationEventTarget(),
                0,
                nil
            )
            
            if result != noErr {
                AppLogger.shared.info("Attempted to register dummy hotkey to trigger accessibility prompt")
            }
        }
        
        return isTrusted
    }
    
    func requestAccessibilityPermissions() {
        // First try the standard accessibility prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if !isTrusted {
            // If that doesn't work, manually open System Settings to the accessibility page
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
        }
    }
}