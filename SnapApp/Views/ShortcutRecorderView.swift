//
//  ShortcutRecorderView.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import SwiftUI
import AppKit

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var keyCode: Int
    @Binding var modifierFlags: NSEvent.ModifierFlags
    @Binding var isRecording: Bool
    
    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.delegate = context.coordinator
        return view
    }
    
    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.isRecording = isRecording
        nsView.keyCode = keyCode
        nsView.modifierFlags = modifierFlags
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: ShortcutRecorderDelegate {
        let parent: ShortcutRecorderView
        
        init(_ parent: ShortcutRecorderView) {
            self.parent = parent
        }
        
        func shortcutRecorded(keyCode: Int, modifierFlags: NSEvent.ModifierFlags) {
            parent.keyCode = keyCode
            parent.modifierFlags = modifierFlags
            parent.isRecording = false
        }
        
        func recordingCancelled() {
            parent.isRecording = false
        }
    }
}

protocol ShortcutRecorderDelegate: AnyObject {
    func shortcutRecorded(keyCode: Int, modifierFlags: NSEvent.ModifierFlags)
    func recordingCancelled()
}

class ShortcutRecorderNSView: NSView {
    weak var delegate: ShortcutRecorderDelegate?
    var isRecording: Bool = false {
        didSet {
            needsDisplay = true
            if isRecording {
                window?.makeFirstResponder(self)
            }
        }
    }
    var keyCode: Int = 0 {
        didSet { needsDisplay = true }
    }
    var modifierFlags: NSEvent.ModifierFlags = [] {
        didSet { needsDisplay = true }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 6
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func becomeFirstResponder() -> Bool {
        needsDisplay = true
        return super.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        isRecording = false
        needsDisplay = true
        return super.resignFirstResponder()
    }
    
    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }
        
        // Ignore modifier-only key presses
        if event.keyCode == 54 || event.keyCode == 55 || event.keyCode == 56 || 
           event.keyCode == 57 || event.keyCode == 58 || event.keyCode == 59 ||
           event.keyCode == 60 || event.keyCode == 61 || event.keyCode == 62 {
            return
        }
        
        // Cancel recording on Escape
        if event.keyCode == 53 {
            delegate?.recordingCancelled()
            return
        }
        
        // Only accept shortcuts with at least one modifier
        let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if !modifiers.isEmpty {
            delegate?.shortcutRecorded(keyCode: Int(event.keyCode), modifierFlags: modifiers)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            isRecording = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let rect = bounds.insetBy(dx: 8, dy: 4)
        
        var displayText: String
        if isRecording {
            displayText = "Press keys..."
        } else if keyCode > 0 {
            displayText = displayStringFromKeyCode(keyCode, modifierFlags: modifierFlags)
        } else {
            displayText = "Click to record shortcut"
        }
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13),
            .foregroundColor: isRecording ? NSColor.systemBlue : NSColor.labelColor
        ]
        
        let attributedString = NSAttributedString(string: displayText, attributes: attributes)
        let textRect = attributedString.boundingRect(with: rect.size, options: [], context: nil)
        
        let centeredRect = NSRect(
            x: rect.midX - textRect.width / 2,
            y: rect.midY - textRect.height / 2,
            width: textRect.width,
            height: textRect.height
        )
        
        attributedString.draw(in: centeredRect)
    }
    
    private func displayStringFromKeyCode(_ keyCode: Int, modifierFlags: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        
        if modifierFlags.contains(.command) {
            components.append("⌘")
        }
        if modifierFlags.contains(.option) {
            components.append("⌥")
        }
        if modifierFlags.contains(.control) {
            components.append("⌃")
        }
        if modifierFlags.contains(.shift) {
            components.append("⇧")
        }
        
        if let keyString = keyCodeToString(keyCode) {
            components.append(keyString)
        }
        
        return components.joined()
    }
    
    private func keyCodeToString(_ keyCode: Int) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 49: return "Space"
        case 36: return "Return"
        case 48: return "Tab"
        case 51: return "Delete"
        case 53: return "Escape"
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default: return nil
        }
    }
}