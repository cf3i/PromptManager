//
//  Shortcuts.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import Foundation
#if os(macOS)
import Carbon.HIToolbox
#endif

enum ShortcutAction: String, CaseIterable, Identifiable, Codable {
    case quickAdd
    case quickPicker

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickAdd:
            return "Quick Add"
        case .quickPicker:
            return "Quick Picker"
        }
    }

    var defaultShortcut: ShortcutDefinition {
        switch self {
        case .quickAdd:
            return ShortcutDefinition(key: .n, command: true, option: true, shift: false, control: true)
        case .quickPicker:
            return ShortcutDefinition(key: .p, command: true, option: true, shift: false, control: true)
        }
    }
}

enum ShortcutKey: String, CaseIterable, Codable, Identifiable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case h = "H"
    case i = "I"
    case j = "J"
    case k = "K"
    case l = "L"
    case m = "M"
    case n = "N"
    case o = "O"
    case p = "P"
    case q = "Q"
    case r = "R"
    case s = "S"
    case t = "T"
    case u = "U"
    case v = "V"
    case w = "W"
    case x = "X"
    case y = "Y"
    case z = "Z"
    case num0 = "0"
    case num1 = "1"
    case num2 = "2"
    case num3 = "3"
    case num4 = "4"
    case num5 = "5"
    case num6 = "6"
    case num7 = "7"
    case num8 = "8"
    case num9 = "9"

    var id: String { rawValue }

#if os(macOS)
    var carbonKeyCode: UInt32 {
        switch self {
        case .a: return UInt32(kVK_ANSI_A)
        case .b: return UInt32(kVK_ANSI_B)
        case .c: return UInt32(kVK_ANSI_C)
        case .d: return UInt32(kVK_ANSI_D)
        case .e: return UInt32(kVK_ANSI_E)
        case .f: return UInt32(kVK_ANSI_F)
        case .g: return UInt32(kVK_ANSI_G)
        case .h: return UInt32(kVK_ANSI_H)
        case .i: return UInt32(kVK_ANSI_I)
        case .j: return UInt32(kVK_ANSI_J)
        case .k: return UInt32(kVK_ANSI_K)
        case .l: return UInt32(kVK_ANSI_L)
        case .m: return UInt32(kVK_ANSI_M)
        case .n: return UInt32(kVK_ANSI_N)
        case .o: return UInt32(kVK_ANSI_O)
        case .p: return UInt32(kVK_ANSI_P)
        case .q: return UInt32(kVK_ANSI_Q)
        case .r: return UInt32(kVK_ANSI_R)
        case .s: return UInt32(kVK_ANSI_S)
        case .t: return UInt32(kVK_ANSI_T)
        case .u: return UInt32(kVK_ANSI_U)
        case .v: return UInt32(kVK_ANSI_V)
        case .w: return UInt32(kVK_ANSI_W)
        case .x: return UInt32(kVK_ANSI_X)
        case .y: return UInt32(kVK_ANSI_Y)
        case .z: return UInt32(kVK_ANSI_Z)
        case .num0: return UInt32(kVK_ANSI_0)
        case .num1: return UInt32(kVK_ANSI_1)
        case .num2: return UInt32(kVK_ANSI_2)
        case .num3: return UInt32(kVK_ANSI_3)
        case .num4: return UInt32(kVK_ANSI_4)
        case .num5: return UInt32(kVK_ANSI_5)
        case .num6: return UInt32(kVK_ANSI_6)
        case .num7: return UInt32(kVK_ANSI_7)
        case .num8: return UInt32(kVK_ANSI_8)
        case .num9: return UInt32(kVK_ANSI_9)
        }
    }
#endif
}

struct ShortcutDefinition: Codable, Hashable {
    var key: ShortcutKey
    var command: Bool
    var option: Bool
    var shift: Bool
    var control: Bool

    var hasModifier: Bool {
        command || option || shift || control
    }

    var displayText: String {
        var text = ""
        if control { text += "⌃" }
        if option { text += "⌥" }
        if shift { text += "⇧" }
        if command { text += "⌘" }
        text += key.rawValue
        return text
    }

#if os(macOS)
    var carbonModifiers: UInt32 {
        var modifiers: UInt32 = 0
        if command { modifiers |= UInt32(cmdKey) }
        if option { modifiers |= UInt32(optionKey) }
        if shift { modifiers |= UInt32(shiftKey) }
        if control { modifiers |= UInt32(controlKey) }
        return modifiers
    }
#endif
}
