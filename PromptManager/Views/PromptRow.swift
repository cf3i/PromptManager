//
//  PromptRow.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct PromptRow: View {
    let prompt: Prompt
    let onCopy: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(prompt.title)
                        .font(.headline)
                        .lineLimit(1)
                    if prompt.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                    }
                }

                Text(prompt.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if !prompt.tags.isEmpty {
                    TagWrapView(tags: prompt.tags)
                }
            }

            Spacer(minLength: 4)

            Button(action: onCopy) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .help("Copy")
        }
        .padding(.vertical, 4)
    }
}
