//
//  SnapAppApp.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import SwiftUI
import AppKit

@main
struct SnapAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        // Create a window that never appears - the AppDelegate handles all UI
        Window("SnapApp", id: "main") {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
        .windowLevel(.floating)
    }
}
