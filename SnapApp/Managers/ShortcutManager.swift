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
        
        if hasConflict(shortcut) {
            AppLogger.shared.warning("Shortcut conflict detected for: \(shortcut.displayString)")
        }
        
        shortcuts.append(shortcut)
        saveShortcuts()
        
        AppLogger.shared.info("Shortcut '\(shortcut.name)' added successfully")
    }
    
    func removeShortcut(withId id: UUID) {
        AppLogger.shared.info("Removing shortcut with id: \(id)")
        
        shortcuts.removeAll { $0.id == id }
        saveShortcuts()
    }
    
    func updateShortcut(_ shortcut: Shortcut) {
        guard let index = shortcuts.firstIndex(where: { $0.id == shortcut.id }) else { return }
        
        AppLogger.shared.info("Updating shortcut: \(shortcut.name)")
        
        shortcuts[index] = shortcut
        saveShortcuts()
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
        
        // Placeholder for command execution - will be implemented in Phase 3
        // For now, just log that the shortcut was triggered
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "SnapApp"
            alert.informativeText = "Shortcut '\(shortcut.name)' would execute:\n\(shortcut.command)\n\n(Command execution will be implemented in Phase 3)"
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func testShortcut(_ shortcut: Shortcut) {
        executeShortcut(withId: shortcut.id)
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
        } catch {
            AppLogger.shared.error("Failed to load shortcuts: \(error)")
        }
    }
}