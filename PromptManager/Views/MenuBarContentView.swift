//
//  MenuBarContentView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI
#if os(macOS)

struct MenuBarContentView: View {
    @EnvironmentObject private var store: PromptStore
    @EnvironmentObject private var shortcutStore: ShortcutStore

    private var recentPrompts: [Prompt] {
        store.prompts
            .sorted {
                ($0.lastUsedAt ?? $0.updatedAt) > ($1.lastUsedAt ?? $1.updatedAt)
            }
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Quick Add (\(shortcutStore.quickAddDisplay))") {
                AppActions.requestQuickAdd()
            }

            Button("Add Clipboard as Prompt") {
                _ = store.quickAddFromClipboard()
            }

            Button("Open Quick Picker (\(shortcutStore.quickPickerDisplay))") {
                QuickPickerWindowController.shared.toggle()
            }

            Button("Shortcut Settings...") {
                AppActions.requestShortcutSettings()
            }

            Divider()

            Text("Recent")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if recentPrompts.isEmpty {
                Text("No prompts yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentPrompts) { prompt in
                    Button(prompt.title) {
                        store.copyPrompt(withID: prompt.id)
                    }
                    .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
#endif
