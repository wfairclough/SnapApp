//
//  PreferencesView.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import SwiftUI
import AppKit

struct PreferencesView: View {
    @StateObject private var shortcutManager = ShortcutManager.shared
    @State private var showingAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bolt.circle")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Text("SnapApp")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Global Shortcut Manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                Divider()
                
                // Shortcuts List
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Shortcuts")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    
                    if shortcutManager.shortcuts.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 24))
                                .foregroundColor(.secondary)
                            
                            Text("No shortcuts configured")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Click + to add your first shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                    } else {
                        List {
                            ForEach(shortcutManager.shortcuts) { shortcut in
                                ShortcutRowView(shortcut: shortcut)
                            }
                            .onDelete(perform: deleteShortcuts)
                        }
                        .listStyle(.plain)
                    }
                }
                
                Spacer()
                
                // Status info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Phase 3: Command Execution ✓")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("• Bash command execution ✓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Security warnings ✓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Timeout & error handling ✓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
            .navigationTitle("Preferences")
        }
        .frame(minWidth: 500, minHeight: 400)
        .sheet(isPresented: $showingAddSheet) {
            AddShortcutView()
        }
    }
    
    private func deleteShortcuts(offsets: IndexSet) {
        for index in offsets {
            let shortcut = shortcutManager.shortcuts[index]
            shortcutManager.removeShortcut(withId: shortcut.id)
        }
    }
}

struct ShortcutRowView: View {
    let shortcut: Shortcut
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.name)
                    .font(.headline)
                
                Text(shortcut.command)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(shortcut.displayString)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.blue)
                
                HStack(spacing: 8) {
                    Button("Test") {
                        shortcutManager.testShortcut(shortcut)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    
                    Toggle("", isOn: .constant(shortcut.isEnabled))
                        .scaleEffect(0.8)
                        .disabled(true)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct AddShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    @State private var name: String = ""
    @State private var command: String = ""
    @State private var keyCode: Int = 0
    @State private var modifierFlags: NSEvent.ModifierFlags = []
    @State private var isRecording: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Shortcut")
                .font(.headline)
            
            Form {
                Section {
                    TextField("Shortcut name", text: $name)
                    
                    TextField("Command to execute", text: $command)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard Shortcut")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ShortcutRecorderView(
                            keyCode: $keyCode,
                            modifierFlags: $modifierFlags,
                            isRecording: $isRecording
                        )
                        .frame(height: 32)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add Shortcut") {
                    let shortcut = Shortcut(
                        name: name,
                        keyCode: keyCode,
                        modifierFlags: modifierFlags,
                        command: command
                    )
                    shortcutManager.addShortcut(shortcut)
                    dismiss()
                }
                .disabled(name.isEmpty || command.isEmpty || keyCode == 0)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 400, height: 300)
    }
}

#Preview {
    PreferencesView()
}