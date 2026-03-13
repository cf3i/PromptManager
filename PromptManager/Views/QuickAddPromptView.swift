//
//  QuickAddPromptView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct QuickAddPromptView: View {
    @EnvironmentObject private var store: PromptStore
    @Environment(\.dismiss) private var dismiss

    let onSave: (PromptDraft) -> Void
    var onClose: (() -> Void)? = nil

    @State private var content = ""
    @State private var tags = ""
    @State private var triedSubmit = false

    private var contentIsValid: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var titlePreview: String {
        guard contentIsValid else {
            return "Title will be generated automatically."
        }
        return store.suggestedTitle(from: content)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Capture")
                .font(.title2.weight(.semibold))

            HStack {
                TextField("Tags (comma separated)", text: $tags)
                    .textFieldStyle(.roundedBorder)
                Button("Paste Clipboard") {
                    pasteClipboard()
                }
            }

            ZStack(alignment: .topLeading) {
                if content.isEmpty {
                    Text("Paste your prompt content here...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        .padding(.leading, 6)
                }
                TextEditor(text: $content)
                    .frame(minHeight: 210)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2))
            )

            Text("Title: \(titlePreview)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if triedSubmit && !contentIsValid {
                Text("Content is required.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    close()
                }
                Button("Save") {
                    triedSubmit = true
                    guard contentIsValid else {
                        return
                    }

                    let cleanedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSave(
                        PromptDraft(
                            title: store.suggestedTitle(from: cleanedContent),
                            content: cleanedContent,
                            tags: tags,
                            isFavorite: false
                        )
                    )
                    close()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 500, minHeight: 360)
        .onAppear {
            if content.isEmpty {
                pasteClipboard()
            }
        }
    }

    private func pasteClipboard() {
        guard let clipboard = store.clipboardText()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboard.isEmpty else {
            return
        }
        content = clipboard
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }
}
