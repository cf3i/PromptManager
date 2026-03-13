//
//  PromptEditorView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct PromptEditorView: View {
    enum Mode {
        case create
        case edit(Prompt)

        var title: String {
            switch self {
            case .create:
                return "New Prompt"
            case .edit:
                return "Edit Prompt"
            }
        }
    }

    let mode: Mode
    let onSave: (PromptDraft) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var isFavorite = false

    @State private var triedSubmit = false

    private var formIsValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(mode: Mode, onSave: @escaping (PromptDraft) -> Void) {
        self.mode = mode
        self.onSave = onSave

        switch mode {
        case .create:
            _title = State(initialValue: "")
            _content = State(initialValue: "")
            _tags = State(initialValue: "")
            _isFavorite = State(initialValue: false)
        case .edit(let prompt):
            _title = State(initialValue: prompt.title)
            _content = State(initialValue: prompt.content)
            _tags = State(initialValue: prompt.tags.joined(separator: ", "))
            _isFavorite = State(initialValue: prompt.isFavorite)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(mode.title)
                .font(.title2.weight(.semibold))

            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)

            TextField("Tags (comma separated)", text: $tags)
                .textFieldStyle(.roundedBorder)

            Toggle("Favorite", isOn: $isFavorite)

            Text("Prompt Content")
                .font(.subheadline.weight(.semibold))

            TextEditor(text: $content)
                .frame(minHeight: 220)
                .font(.body)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )

            if triedSubmit && !formIsValid {
                Text("Title and content are required.")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Save") {
                    triedSubmit = true
                    guard formIsValid else { return }
                    let draft = PromptDraft(
                        title: title,
                        content: content,
                        tags: tags,
                        isFavorite: isFavorite
                    )
                    onSave(draft)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 640, minHeight: 500)
    }
}
