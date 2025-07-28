//
//  AppDelegate.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppLogger.shared.info("SnapApp starting up...")
        
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Create status bar item
        setupStatusBarItem()
        
        // Trigger accessibility permission request on startup
        // This will make the app appear in System Settings if it doesn't have permission
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let hasPermission = GlobalHotkeyManager.shared.checkAccessibilityPermissions()
            AppLogger.shared.info("Accessibility permission status: \(hasPermission)")
            if !hasPermission {
                AppLogger.shared.info("App will appear in System Settings accessibility list after attempting to use features")
            }
        }
        
        AppLogger.shared.info("SnapApp successfully launched as menubar app")
    }
    
    private func setupStatusBarItem() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "bolt.circle", accessibilityDescription: "SnapApp")
            button.toolTip = "SnapApp - Shortcut Manager"
        }
        
        // Create menu
        let menu = NSMenu()
        
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        preferencesItem.target = self
        menu.addItem(preferencesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit SnapApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusBarItem.menu = menu
    }
    
    @objc private func openPreferences() {
        if let settingsWindow = settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create a new settings window
        let preferencesView = PreferencesView()
        let hostingController = NSHostingController(rootView: preferencesView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "SnapApp Preferences"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("PreferencesWindow")
        
        // Store reference and show window
        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Clear reference when window closes
        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: window, queue: .main) { [weak self] _ in
            self?.settingsWindow = nil
        }
    }
}