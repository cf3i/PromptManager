//
//  PromptManagerApp.swift
//  PromptManager
//
//  Created by Chao Fei on 13/03/2026.
//

import SwiftUI

@main
struct PromptManagerApp: App {
    @StateObject private var store = PromptStore.shared
    @StateObject private var shortcutStore = ShortcutStore.shared
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
#if os(macOS)
                .environmentObject(shortcutStore)
#endif
        }
#if os(macOS)
        .commands {
            CommandMenu("Prompt") {
                Button("Quick Add") {
                    AppActions.requestQuickAdd()
                }

                Button("Add Clipboard as Prompt") {
                    _ = store.quickAddFromClipboard()
                }

                Button("Quick Picker") {
                    QuickPickerWindowController.shared.toggle()
                }

                Divider()

                Button("Shortcut Settings...") {
                    AppActions.requestShortcutSettings()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
#endif

#if os(macOS)
        MenuBarExtra("PromptManager", systemImage: "text.quote") {
            MenuBarContentView()
                .environmentObject(store)
                .environmentObject(shortcutStore)
        }

        Settings {
            ShortcutSettingsView()
                .environmentObject(shortcutStore)
        }
#endif
    }
}
