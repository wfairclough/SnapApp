//
//  Shortcut.swift
//  SnapApp
//
//  Created by Will Fairclough on 2025-07-27.
//

import Foundation
import AppKit

struct Shortcut: Codable, Identifiable {
    let id: UUID
    let name: String
    let keyCode: Int
    let modifierFlags: NSEvent.ModifierFlags
    let command: String
    let isEnabled: Bool
    let createdDate: Date
    
    init(name: String, keyCode: Int, modifierFlags: NSEvent.ModifierFlags, command: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.name = name
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.command = command
        self.isEnabled = isEnabled
        self.createdDate = Date()
    }
    
    init(id: UUID, name: String, keyCode: Int, modifierFlags: NSEvent.ModifierFlags, command: String, isEnabled: Bool, createdDate: Date) {
        self.id = id
        self.name = name
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.command = command
        self.isEnabled = isEnabled
        self.createdDate = createdDate
    }
    
    var displayString: String {
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

extension NSEvent.ModifierFlags: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(UInt.self)
        self.init(rawValue: rawValue)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
}