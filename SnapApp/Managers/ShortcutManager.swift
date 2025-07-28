//
//  ShortcutManager.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import Foundation
import AppKit

class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    @Published var shortcuts: [Shortcut] = []
    private let userDefaults = UserDefaults.standard
    private let shortcutsKey = "SnapApp_Shortcuts"
    
    private init() {
        loadShortcuts()
        AppLogger.shared.info("ShortcutManager initialized with \(shortcuts.count) shortcuts")
    }
    
    func addShortcut(_ shortcut: Shortcut) {
        AppLogger.shared.info("Adding shortcut: \(shortcut.name)")
        
        // Handle conflicts by disabling existing shortcuts with same key combination
        if hasConflict(shortcut) {
            AppLogger.shared.warning("Shortcut conflict detected for: \(shortcut.displayString)")
            
            // Disable conflicting shortcuts
            for index in shortcuts.indices {
                let existing = shortcuts[index]
                if existing.keyCode == shortcut.keyCode &&
                   existing.modifierFlags == shortcut.modifierFlags &&
                   existing.isEnabled {
                    
                    AppLogger.shared.info("Disabling conflicting shortcut: \(existing.name)")
                    
                    // Unregister the old hotkey
                    GlobalHotkeyManager.shared.unregisterHotkey(existing)
                    
                    shortcuts[index] = Shortcut(
                        id: existing.id,
                        name: existing.name,
                        keyCode: existing.keyCode,
                        modifierFlags: existing.modifierFlags,
                        command: existing.command,
                        isEnabled: false,
                        createdDate: existing.createdDate
                    )
                }
            }
        }
        
        shortcuts.append(shortcut)
        saveShortcuts()
        
        // Register the new hotkey if enabled
        if shortcut.isEnabled {
            let success = GlobalHotkeyManager.shared.registerHotkey(shortcut)
            if !success {
                AppLogger.shared.warning("Failed to register global hotkey for: \(shortcut.name)")
            }
        }
        
        AppLogger.shared.info("Shortcut '\(shortcut.name)' added successfully")
    }
    
    func removeShortcut(withId id: UUID) {
        AppLogger.shared.info("Removing shortcut with id: \(id)")
        
        // Find and unregister the hotkey before removing
        if let shortcut = shortcuts.first(where: { $0.id == id }) {
            GlobalHotkeyManager.shared.unregisterHotkey(shortcut)
        }
        
        shortcuts.removeAll { $0.id == id }
        saveShortcuts()
    }
    
    func updateShortcut(_ shortcut: Shortcut) {
        guard let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }
        
        AppLogger.shared.info("Updating shortcut: \(shortcut.name)")
        
        let oldShortcut = shortcuts[index]
        
        // Unregister old hotkey
        GlobalHotkeyManager.shared.unregisterHotkey(oldShortcut)
        
        shortcuts[index] = shortcut
        saveShortcuts()
        
        // Register new hotkey if enabled
        if shortcut.isEnabled {
            let success = GlobalHotkeyManager.shared.registerHotkey(shortcut)
            if !success {
                AppLogger.shared.warning("Failed to register global hotkey for updated shortcut: \(shortcut.name)")
            }
        }
    }
    
    private func hasConflict(_ shortcut: Shortcut) -> Bool {
        return shortcuts.contains { existing in
            existing.keyCode == shortcut.keyCode && 
            existing.modifierFlags == shortcut.modifierFlags &&
            existing.isEnabled &&
            existing.id != shortcut.id
        }
    }
    
    func executeShortcut(withId id: UUID) {
        guard let shortcut = shortcuts.first(where: { $0.id == id }) else { return }
        
        AppLogger.shared.info("Executing shortcut: \(shortcut.name)")
        AppLogger.shared.debug("Command: \(shortcut.command)")
        
        Task {
            let result = await CommandExecutor.shared.executeCommand(shortcut.command)
            
            // Log the result but don't show UI dialog for global shortcuts
            AppLogger.shared.info("Shortcut '\(shortcut.name)' completed with exit code: \(result.exitCode)")
            if !result.output.isEmpty {
                AppLogger.shared.debug("Output: \(result.output)")
            }
            if !result.error.isEmpty {
                AppLogger.shared.debug("Error: \(result.error)")
            }
        }
    }
    
    private func showCommandResult(for shortcut: Shortcut, result: CommandResult) {
        let alert = NSAlert()
        
        if result.exitCode == 0 {
            alert.messageText = "Command Executed Successfully"
            alert.alertStyle = .informational
            
            if result.output.isEmpty {
                alert.informativeText = "Shortcut '\(shortcut.name)' completed successfully.\n\nExecution time: \(String(format: "%.2f", result.executionTime))s"
            } else {
                alert.informativeText = "Shortcut '\(shortcut.name)' completed successfully.\n\nOutput:\n\(result.output.trimmingCharacters(in: .whitespacesAndNewlines))\n\nExecution time: \(String(format: "%.2f", result.executionTime))s"
            }
        } else if result.exitCode == -1 {
            alert.messageText = "Command Failed"
            alert.alertStyle = .critical
            alert.informativeText = "Shortcut '\(shortcut.name)' failed to execute.\n\nError: \(result.error)"
        } else {
            alert.messageText = "Command Completed with Errors"
            alert.alertStyle = .warning
            
            var message = "Shortcut '\(shortcut.name)' completed with exit code \(result.exitCode)."
            
            if !result.output.isEmpty {
                message += "\n\nOutput:\n\(result.output.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            
            if !result.error.isEmpty {
                message += "\n\nError:\n\(result.error.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            
            message += "\n\nExecution time: \(String(format: "%.2f", result.executionTime))s"
            
            alert.informativeText = message
        }
        
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func testShortcut(_ shortcut: Shortcut) {
        AppLogger.shared.info("Testing shortcut: \(shortcut.name)")
        AppLogger.shared.debug("Command: \(shortcut.command)")
        
        Task {
            let result = await CommandExecutor.shared.executeCommand(shortcut.command)
            
            await MainActor.run {
                showCommandResult(for: shortcut, result: result)
            }
        }
    }
    
    private func saveShortcuts() {
        do {
            let data = try JSONEncoder().encode(shortcuts)
            userDefaults.set(data, forKey: shortcutsKey)
            AppLogger.shared.info("Shortcuts saved to UserDefaults")
        } catch {
            AppLogger.shared.error("Failed to save shortcuts: \(error)")
        }
    }
    
    private func loadShortcuts() {
        guard let data = userDefaults.data(forKey: shortcutsKey) else {
            AppLogger.shared.info("No saved shortcuts found")
            return
        }
        
        do {
            shortcuts = try JSONDecoder().decode([Shortcut].self, from: data)
            AppLogger.shared.info("Loaded \(shortcuts.count) shortcuts from UserDefaults")
            
            // Don't register hotkeys here - they will be registered when the app is fully ready
            AppLogger.shared.info("Shortcuts loaded, hotkey registration will occur after app startup")
        } catch {
            AppLogger.shared.error("Failed to load shortcuts: \(error)")
        }
    }
    
    func registerAllHotkeys() {
        AppLogger.shared.info("Registering all enabled hotkeys...")
        
        for shortcut in shortcuts {
            if shortcut.isEnabled {
                let success = GlobalHotkeyManager.shared.registerHotkey(shortcut)
                if success {
                    AppLogger.shared.info("Registered hotkey: \(shortcut.name)")
                } else {
                    AppLogger.shared.warning("Failed to register hotkey: \(shortcut.name)")
                }
            }
        }
        
        AppLogger.shared.info("Hotkey registration complete")
    }
    
    func reregisterAllHotkeys() {
        AppLogger.shared.info("Re-registering all hotkeys...")
        
        // First unregister any existing hotkeys
        GlobalHotkeyManager.shared.unregisterAllHotkeys()
        
        // Then register all enabled shortcuts
        registerAllHotkeys()
    }
}