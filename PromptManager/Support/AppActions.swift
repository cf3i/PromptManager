//
//  AppActions.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import Foundation
#if os(macOS)
import AppKit
#endif

extension Notification.Name {
    static let promptManagerQuickAddRequested = Notification.Name("promptManager.quickAddRequested")
    static let promptManagerShortcutSettingsRequested = Notification.Name("promptManager.shortcutSettingsRequested")
}

enum AppActions {
    static func requestQuickAdd() {
#if os(macOS)
        NSApp.activate(ignoringOtherApps: true)
        QuickAddWindowController.shared.show()
#else
        NotificationCenter.default.post(name: .promptManagerQuickAddRequested, object: nil)
#endif
    }

    static func requestShortcutSettings() {
#if os(macOS)
        NSApp.activate(ignoringOtherApps: true)
        ShortcutSettingsWindowController.shared.show()
#else
        NotificationCenter.default.post(name: .promptManagerShortcutSettingsRequested, object: nil)
#endif
    }
}
