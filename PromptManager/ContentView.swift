//
//  ContentView.swift
//  PromptManager
//
//  Created by Chao Fei on 13/03/2026.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PromptStore

    @State private var searchText = ""
    @State private var selectedPromptID: UUID?
    @State private var selectedTags = Set<String>()

#if !os(macOS)
    @State private var isShowingQuickAddSheet = false
#endif
    @State private var isShowingNewPromptSheet = false
    @State private var editingPrompt: Prompt?
    @State private var isShowingTagManager = false
    @State private var deletingPrompt: Prompt?

    private var filteredPrompts: [Prompt] {
        store.filteredPrompts(searchText: searchText, selectedTags: selectedTags)
    }

    private var selectedPrompt: Prompt? {
        guard let selectedPromptID else { return nil }
        return store.prompt(withID: selectedPromptID)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 12) {
                TextField("Search title/content/tag", text: $searchText)
                    .textFieldStyle(.roundedBorder)

                TagFilterBar(
                    allTags: store.sortedDefinedTags,
                    selectedTags: $selectedTags
                )

                List(filteredPrompts, selection: $selectedPromptID) { prompt in
                    PromptRow(prompt: prompt) {
                        store.copyPrompt(withID: prompt.id)
                    }
                    .tag(prompt.id)
                    .contextMenu {
                        Button("Copy to Clipboard") {
                            store.copyPrompt(withID: prompt.id)
                        }
                        Button("Edit") {
                            editingPrompt = prompt
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            deletingPrompt = prompt
                        }
                    }
                }
            }
            .padding(12)
            .navigationTitle("Prompt Library")
            .toolbar {
                ToolbarItemGroup {
                    Button {
#if os(macOS)
                        AppActions.requestQuickAdd()
#else
                        isShowingQuickAddSheet = true
#endif
                    } label: {
                        Label("Quick Add", systemImage: "bolt.badge.plus")
                    }

                    Button {
                        isShowingTagManager = true
                    } label: {
                        Label("Tags", systemImage: "tag")
                    }

                    Button {
                        isShowingNewPromptSheet = true
                    } label: {
                        Label("New Prompt", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Group {
                if let prompt = selectedPrompt {
                    PromptDetailView(
                        prompt: prompt,
                        onCopy: {
                            store.copyPrompt(withID: prompt.id)
                        },
                        onToggleFavorite: {
                            store.toggleFavorite(promptID: prompt.id)
                        },
                        onEdit: {
                            editingPrompt = prompt
                        },
                        onDelete: {
                            deletingPrompt = prompt
                        }
                    )
                } else {
                    ContentUnavailableView(
                        "No Prompt Selected",
                        systemImage: "text.quote",
                        description: Text("Create one or choose from the list.")
                    )
                }
            }
            .padding(20)
        }
        .overlay(alignment: .bottomTrailing) {
            if let copyMessage = store.copyToastMessage {
                CopyToastView(text: copyMessage)
                    .padding(20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.copyToastMessage)
#if !os(macOS)
        .sheet(isPresented: $isShowingQuickAddSheet) {
            QuickAddPromptView { draft in
                store.createPrompt(from: draft)
                selectedPromptID = store.prompts.last?.id
            }
            .environmentObject(store)
        }
#endif
        .sheet(isPresented: $isShowingNewPromptSheet) {
            PromptEditorView(mode: .create) { draft in
                store.createPrompt(from: draft)
                selectedPromptID = store.prompts.last?.id
            }
        }
        .sheet(item: $editingPrompt) { prompt in
            PromptEditorView(mode: .edit(prompt)) { draft in
                store.updatePrompt(promptID: prompt.id, with: draft)
            }
        }
        .sheet(isPresented: $isShowingTagManager) {
            TagManagerView()
                .environmentObject(store)
        }
        .alert(
            "Delete Prompt?",
            isPresented: Binding(
                get: { deletingPrompt != nil },
                set: { if !$0 { deletingPrompt = nil } }
            ),
            presenting: deletingPrompt
        ) { prompt in
            Button("Delete", role: .destructive) {
                store.deletePrompt(withID: prompt.id)
                if selectedPromptID == prompt.id {
                    selectedPromptID = nil
                }
                deletingPrompt = nil
            }
            Button("Cancel", role: .cancel) {
                deletingPrompt = nil
            }
        } message: { prompt in
            Text("\"\(prompt.title)\" will be permanently removed.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PromptStore.preview())
}
