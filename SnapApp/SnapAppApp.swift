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
        // Minimal scene - AppDelegate handles all UI
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .hidden()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
