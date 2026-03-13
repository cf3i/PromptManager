//
//  QuickPickerView.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import SwiftUI

struct QuickPickerView: View {
    @ObservedObject var store: PromptStore
    let onPick: (Prompt) -> Void
    let onClose: () -> Void

    @State private var searchText = ""
    @FocusState private var searchFocused: Bool

    private var results: [Prompt] {
        store.filteredPrompts(searchText: searchText, selectedTags: [])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Type to find a prompt...", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                    .onSubmit {
                        if let first = results.first {
                            onPick(first)
                        }
                    }
                Button("Close", action: onClose)
                    .keyboardShortcut(.cancelAction)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.1))
            )

            if results.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Match",
                    systemImage: "text.magnifyingglass",
                    description: Text("Try another keyword or add more prompts in the main window.")
                )
                Spacer()
            } else {
                List(results) { prompt in
                    Button {
                        onPick(prompt)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(prompt.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Spacer()
                                if prompt.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
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
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.inset)
            }
        }
        .padding(16)
        .frame(minWidth: 700, minHeight: 460)
        .onAppear {
            searchText = ""
            searchFocused = true
        }
#if os(macOS)
        .onExitCommand {
            onClose()
        }
#endif
    }
}
