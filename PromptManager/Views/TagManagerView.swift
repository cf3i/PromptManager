//
//  TagManagerView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct TagManagerView: View {
    @EnvironmentObject private var store: PromptStore
    @Environment(\.dismiss) private var dismiss

    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tag Manager")
                .font(.title2.weight(.semibold))

            HStack {
                TextField("New tag", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addTag)
                Button("Add", action: addTag)
            }

            List {
                ForEach(store.sortedDefinedTags, id: \.self) { tag in
                    TagRowView(
                        tag: tag,
                        usageCount: store.usageCount(for: tag),
                        onRename: { oldName, newName in
                            store.renameTag(from: oldName, to: newName)
                        },
                        onDelete: { name in
                            store.deleteTag(name)
                        }
                    )
                }
            }
            .frame(minHeight: 280)

            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(minWidth: 440, minHeight: 420)
    }

    private func addTag() {
        store.addDefinedTag(newTag)
        newTag = ""
    }
}

private struct TagRowView: View {
    let tag: String
    let usageCount: Int
    let onRename: (String, String) -> Void
    let onDelete: (String) -> Void

    @State private var draftText: String

    init(
        tag: String,
        usageCount: Int,
        onRename: @escaping (String, String) -> Void,
        onDelete: @escaping (String) -> Void
    ) {
        self.tag = tag
        self.usageCount = usageCount
        self.onRename = onRename
        self.onDelete = onDelete
        _draftText = State(initialValue: tag)
    }

    var body: some View {
        HStack(spacing: 10) {
            TextField("Tag", text: $draftText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    onRename(tag, draftText)
                }

            Text("\(usageCount)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            Button("Save") {
                onRename(tag, draftText)
            }
            .buttonStyle(.bordered)

            Button("Delete", role: .destructive) {
                onDelete(tag)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }
}
