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
        
        AppLogger.shared.info("Registering hotkey: \(shortcut.name), keyCode: \(shortcut.keyCode), carbonModifiers: \(carbonModifiers), display: \(shortcut.displayString)")
        
        // Install event handler if not already installed
        installEventHandlerIfNeeded()
        
        var hotkeyRef: EventHotKeyRef?
        let result = RegisterEventHotKey(
            UInt32(shortcut.keyCode),
            carbonModifiers,
            EventHotKeyID(signature: OSType(hotkeyID), id: hotkeyID),
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )
        
        if result == noErr {
            registeredHotkeys[hotkeyID] = shortcut
            AppLogger.shared.info("Successfully registered hotkey: \(shortcut.name) with ID \(hotkeyID)")
            return true
        } else {
            AppLogger.shared.error("Failed to register hotkey: \(shortcut.name), error: \(result)")
            return false
        }
    }
    
    func unregisterHotkey(_ shortcut: Shortcut) {
        // Find and remove the hotkey
        for (hotkeyID, registeredShortcut) in registeredHotkeys {
            if registeredShortcut.id == shortcut.id {
                // Note: GetEventHotKey is not available in sandbox, so we'll track refs differently
                // For now, just remove from our tracking
                registeredHotkeys.removeValue(forKey: hotkeyID)
                AppLogger.shared.info("Unregistered hotkey: \(shortcut.name)")
                break
            }
        }
    }
    
    func unregisterAllHotkeys() {
        for (_, shortcut) in registeredHotkeys {
            AppLogger.shared.info("Unregistered hotkey: \(shortcut.name)")
        }
        registeredHotkeys.removeAll()
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
                
                // Execute the shortcut on the main thread
                DispatchQueue.main.async {
                    ShortcutManager.shared.executeShortcut(withId: shortcut.id)
                }
                
                return noErr
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