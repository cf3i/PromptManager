//
//  PromptDetailView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct PromptDetailView: View {
    let prompt: Prompt
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: prompt.updatedAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.title)
                        .font(.largeTitle.weight(.semibold))
                    HStack(spacing: 10) {
                        Label("Used \(prompt.usageCount)x", systemImage: "repeat")
                        Text("Updated \(dateText)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                HStack {
                    Button(action: onCopy) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    Button(action: onToggleFavorite) {
                        Label(
                            prompt.isFavorite ? "Unfavorite" : "Favorite",
                            systemImage: prompt.isFavorite ? "star.slash" : "star"
                        )
                    }
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }

            if !prompt.tags.isEmpty {
                TagWrapView(tags: prompt.tags)
            }

            Divider()

            ScrollView {
                Text(prompt.content)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }
}
