//
//  ShortcutSettingsView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct ShortcutSettingsView: View {
    @EnvironmentObject private var shortcutStore: ShortcutStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Global Shortcuts")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(ShortcutAction.allCases) { action in
                        ShortcutRow(
                            title: action.title,
                            shortcut: shortcutStore.binding(for: action)
                        )
                    }

                    Text("Each shortcut must include at least one modifier and cannot duplicate another action.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("If a shortcut is used by macOS or another app, PromptManager will show an error and that shortcut will not activate.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let validationMessage = shortcutStore.validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Divider()

            HStack {
                Spacer()
                Button("Reset Defaults") {
                    shortcutStore.resetDefaults()
                }
            }
        }
        .padding(16)
        .frame(minWidth: 620, maxWidth: 620, minHeight: 360)
    }
}

private struct ShortcutRow: View {
    let title: String
    @Binding var shortcut: ShortcutDefinition

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack(spacing: 14) {
                Picker("Key", selection: $shortcut.key) {
                    ForEach(ShortcutKey.allCases) { key in
                        Text(key.rawValue).tag(key)
                    }
                }
                .labelsHidden()
                .frame(width: 84)

                Toggle("⌘", isOn: $shortcut.command)
                Toggle("⌥", isOn: $shortcut.option)
                Toggle("⇧", isOn: $shortcut.shift)
                Toggle("⌃", isOn: $shortcut.control)

                Spacer()

                Text(shortcut.displayText)
                    .font(.body.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(width: 84, alignment: .trailing)
            }
            .toggleStyle(.checkbox)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
