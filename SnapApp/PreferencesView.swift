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
    @State private var hasAccessibilityPermission = false
    
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
                
                // Permissions Check
                if !hasAccessibilityPermission {
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Accessibility Permission Required")
                                .font(.headline)
                                .foregroundColor(.orange)
                        }
                        
                        Text("Global shortcuts require accessibility permissions to work. Click below to grant access in System Settings.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Open System Settings") {
                            GlobalHotkeyManager.shared.requestAccessibilityPermissions()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.orange.opacity(0.1))
                    
                    Divider()
                }
                
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
                    Text("Phase 4: UI & Configuration ✓")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("• Conflict detection ✓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Shortcut editing ✓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("• Visual feedback ✓")
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
        .onAppear {
            checkAccessibilityPermission()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkAccessibilityPermission()
        }
    }
    
    private func deleteShortcuts(offsets: IndexSet) {
        for index in offsets {
            let shortcut = shortcutManager.shortcuts[index]
            shortcutManager.removeShortcut(withId: shortcut.id)
        }
    }
    
    private func checkAccessibilityPermission() {
        hasAccessibilityPermission = GlobalHotkeyManager.shared.checkAccessibilityPermissions()
    }
}

struct ShortcutRowView: View {
    let shortcut: Shortcut
    @StateObject private var shortcutManager = ShortcutManager.shared
    @State private var showingEditSheet = false
    
    private var hasConflict: Bool {
        shortcutManager.shortcuts.contains { other in
            other.id != shortcut.id &&
            other.keyCode == shortcut.keyCode &&
            other.modifierFlags == shortcut.modifierFlags &&
            other.isEnabled &&
            shortcut.isEnabled
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(shortcut.name)
                        .font(.headline)
                    
                    if hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                    
                    if !shortcut.isEnabled {
                        Text("(Disabled)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(shortcut.command)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 4) {
                    Text(shortcut.displayString)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(hasConflict ? .orange : .blue)
                    
                    if hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption2)
                    }
                }
                
                HStack(spacing: 8) {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    
                    Button("Test") {
                        shortcutManager.testShortcut(shortcut)
                    }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
                    .disabled(!shortcut.isEnabled)
                    
                    Toggle("", isOn: Binding(
                        get: { shortcut.isEnabled },
                        set: { enabled in
                            let updatedShortcut = Shortcut(
                                id: shortcut.id,
                                name: shortcut.name,
                                keyCode: shortcut.keyCode,
                                modifierFlags: shortcut.modifierFlags,
                                command: shortcut.command,
                                isEnabled: enabled,
                                createdDate: shortcut.createdDate
                            )
                            shortcutManager.updateShortcut(updatedShortcut)
                        }
                    ))
                    .scaleEffect(0.8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(hasConflict ? Color.orange.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .sheet(isPresented: $showingEditSheet) {
            EditShortcutView(shortcut: shortcut)
        }
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
    @State private var showingConflictWarning = false
    
    private var hasConflict: Bool {
        keyCode != 0 && shortcutManager.shortcuts.contains { existing in
            existing.keyCode == keyCode &&
            existing.modifierFlags == modifierFlags &&
            existing.isEnabled
        }
    }
    
    private var isValidCommand: Bool {
        !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Shortcut")
                .font(.headline)
            
            Form {
                Section {
                    TextField("Shortcut name", text: $name)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Command to execute", text: $command, axis: .vertical)
                            .lineLimit(2...4)
                        
                        if !command.isEmpty && !isValidCommand {
                            Text("Command cannot be empty or whitespace only")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Keyboard Shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if hasConflict {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("Conflict detected")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        ShortcutRecorderView(
                            keyCode: $keyCode,
                            modifierFlags: $modifierFlags,
                            isRecording: $isRecording
                        )
                        .frame(height: 32)
                        
                        if hasConflict {
                            Text("This shortcut is already in use. The existing shortcut will be disabled.")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }
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
                    if hasConflict {
                        showingConflictWarning = true
                    } else {
                        addShortcut()
                    }
                }
                .disabled(name.isEmpty || !isValidCommand || keyCode == 0)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 450, height: 350)
        .alert("Shortcut Conflict", isPresented: $showingConflictWarning) {
            Button("Cancel", role: .cancel) { }
            Button("Add Anyway") {
                addShortcut()
            }
        } message: {
            Text("This keyboard shortcut is already in use. Adding this shortcut will disable the existing one. Do you want to continue?")
        }
    }
    
    private func addShortcut() {
        let shortcut = Shortcut(
            name: name,
            keyCode: keyCode,
            modifierFlags: modifierFlags,
            command: command
        )
        shortcutManager.addShortcut(shortcut)
        dismiss()
    }
}

struct EditShortcutView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var shortcutManager = ShortcutManager.shared
    
    let shortcut: Shortcut
    
    @State private var name: String
    @State private var command: String
    @State private var keyCode: Int
    @State private var modifierFlags: NSEvent.ModifierFlags
    @State private var isRecording: Bool = false
    @State private var isEnabled: Bool
    
    init(shortcut: Shortcut) {
        self.shortcut = shortcut
        self._name = State(initialValue: shortcut.name)
        self._command = State(initialValue: shortcut.command)
        self._keyCode = State(initialValue: shortcut.keyCode)
        self._modifierFlags = State(initialValue: shortcut.modifierFlags)
        self._isEnabled = State(initialValue: shortcut.isEnabled)
    }
    
    private var hasConflict: Bool {
        shortcutManager.shortcuts.contains { other in
            other.id != shortcut.id &&
            other.keyCode == keyCode &&
            other.modifierFlags == modifierFlags &&
            other.isEnabled &&
            isEnabled
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Shortcut")
                .font(.headline)
            
            Form {
                Section {
                    TextField("Shortcut name", text: $name)
                    
                    TextField("Command to execute", text: $command, axis: .vertical)
                        .lineLimit(3...6)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Keyboard Shortcut")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if hasConflict {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption2)
                                Text("Conflict detected")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        ShortcutRecorderView(
                            keyCode: $keyCode,
                            modifierFlags: $modifierFlags,
                            isRecording: $isRecording
                        )
                        .frame(height: 32)
                    }
                    
                    Toggle("Enabled", isOn: $isEnabled)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Save Changes") {
                    let updatedShortcut = Shortcut(
                        id: shortcut.id,
                        name: name,
                        keyCode: keyCode,
                        modifierFlags: modifierFlags,
                        command: command,
                        isEnabled: isEnabled,
                        createdDate: shortcut.createdDate
                    )
                    shortcutManager.updateShortcut(updatedShortcut)
                    dismiss()
                }
                .disabled(name.isEmpty || command.isEmpty || keyCode == 0)
                .keyboardShortcut(.return)
            }
        }
        .padding(20)
        .frame(width: 450, height: 350)
    }
}

#Preview {
    PreferencesView()
}