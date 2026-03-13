//
//  TagComponents.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct TagWrapView: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    TagBadge(text: tag, isSelected: true)
                }
            }
            .padding(.vertical, 1)
        }
        .frame(height: 24)
    }
}

struct TagFilterBar: View {
    let allTags: [String]
    @Binding var selectedTags: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !selectedTags.isEmpty {
                    Button("Clear") {
                        selectedTags.removeAll()
                    }
                    .font(.caption)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(allTags, id: \.self) { tag in
                        let selected = selectedTags.contains(tag)
                        Button {
                            if selected {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            TagBadge(text: tag, isSelected: selected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

struct TagBadge: View {
    let text: String
    let isSelected: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.14))
            )
    }
}
