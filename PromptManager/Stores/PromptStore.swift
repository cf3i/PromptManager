//
//  PromptStore.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import Combine
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

@MainActor
final class PromptStore: ObservableObject {
    static let shared = PromptStore()

    @Published private(set) var prompts: [Prompt] = []
    @Published private(set) var definedTags: [String] = []
    @Published var copyToastMessage: String?

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        load()
    }

    var sortedDefinedTags: [String] {
        definedTags.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    func prompt(withID id: UUID) -> Prompt? {
        prompts.first { $0.id == id }
    }

    func filteredPrompts(searchText: String, selectedTags: Set<String>) -> [Prompt] {
        let normalizedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return prompts
            .filter { prompt in
                let matchesSearch: Bool
                if normalizedSearch.isEmpty {
                    matchesSearch = true
                } else {
                    let searchable = [
                        prompt.title,
                        prompt.content,
                        prompt.tags.joined(separator: " ")
                    ].joined(separator: " ").lowercased()
                    matchesSearch = searchable.contains(normalizedSearch)
                }

                let matchesTags: Bool
                if selectedTags.isEmpty {
                    matchesTags = true
                } else {
                    let promptTagSet = Set(prompt.tags.map { $0.lowercased() })
                    let selectedTagSet = Set(selectedTags.map { $0.lowercased() })
                    matchesTags = !promptTagSet.isDisjoint(with: selectedTagSet)
                }
                return matchesSearch && matchesTags
            }
            .sorted(by: sortPrompts)
    }

    func createPrompt(from draft: PromptDraft) {
        let normalizedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = draft.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedContent.isEmpty else {
            return
        }

        let tags = normalizeTags(from: draft.tags)
        let prompt = Prompt(
            title: normalizedTitle,
            content: normalizedContent,
            tags: tags,
            isFavorite: draft.isFavorite
        )
        prompts.append(prompt)
        register(tags: tags)
        save()
    }

    func updatePrompt(promptID: UUID, with draft: PromptDraft) {
        guard let index = prompts.firstIndex(where: { $0.id == promptID }) else {
            return
        }
        let normalizedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedContent = draft.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty, !normalizedContent.isEmpty else {
            return
        }

        prompts[index].title = normalizedTitle
        prompts[index].content = normalizedContent
        prompts[index].tags = normalizeTags(from: draft.tags)
        prompts[index].isFavorite = draft.isFavorite
        prompts[index].updatedAt = .now

        register(tags: prompts[index].tags)
        save()
    }

    func deletePrompt(withID promptID: UUID) {
        prompts.removeAll { $0.id == promptID }
        removeUnusedDefinedTags()
        save()
    }

    func toggleFavorite(promptID: UUID) {
        guard let index = prompts.firstIndex(where: { $0.id == promptID }) else {
            return
        }
        prompts[index].isFavorite.toggle()
        prompts[index].updatedAt = .now
        save()
    }

    func copyPrompt(withID promptID: UUID) {
        guard let index = prompts.firstIndex(where: { $0.id == promptID }) else {
            return
        }
        copyToClipboard(prompts[index].content)
        prompts[index].lastUsedAt = .now
        prompts[index].usageCount += 1
        prompts[index].updatedAt = .now
        save()
        showToast("Copied: \(prompts[index].title)")
    }

    func quickAddFromClipboard(tags: String = "", isFavorite: Bool = false) -> Bool {
        guard let clipboard = clipboardText()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clipboard.isEmpty else {
            return false
        }
        createPrompt(
            from: PromptDraft(
                title: suggestedTitle(from: clipboard),
                content: clipboard,
                tags: tags,
                isFavorite: isFavorite
            )
        )
        showToast("Saved prompt from clipboard")
        return true
    }

    func clipboardText() -> String? {
#if os(macOS)
        NSPasteboard.general.string(forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string
#else
        nil
#endif
    }

    func suggestedTitle(from content: String) -> String {
        let firstNonEmptyLine = content
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        let raw = firstNonEmptyLine ?? "Untitled Prompt"
        if raw.count <= 42 {
            return raw
        }
        return String(raw.prefix(42)) + "..."
    }

    func addDefinedTag(_ tag: String) {
        let normalized = normalizeSingleTag(tag)
        guard !normalized.isEmpty else {
            return
        }
        if !definedTags.map({ $0.lowercased() }).contains(normalized.lowercased()) {
            definedTags.append(normalized)
            save()
        }
    }

    func renameTag(from oldTag: String, to newTag: String) {
        let normalizedOldTag = normalizeSingleTag(oldTag)
        let normalizedNewTag = normalizeSingleTag(newTag)
        guard !normalizedOldTag.isEmpty, !normalizedNewTag.isEmpty else {
            return
        }
        guard normalizedOldTag.caseInsensitiveCompare(normalizedNewTag) != .orderedSame else {
            return
        }

        for index in prompts.indices {
            let updatedTags = prompts[index].tags.map { tag -> String in
                if tag.caseInsensitiveCompare(normalizedOldTag) == .orderedSame {
                    return normalizedNewTag
                }
                return tag
            }
            prompts[index].tags = uniquePreservingOrder(updatedTags)
            prompts[index].updatedAt = .now
        }

        definedTags = definedTags.map { tag -> String in
            if tag.caseInsensitiveCompare(normalizedOldTag) == .orderedSame {
                return normalizedNewTag
            }
            return tag
        }
        definedTags = uniqueCaseInsensitive(definedTags)
        save()
    }

    func deleteTag(_ tag: String) {
        let normalized = normalizeSingleTag(tag)
        guard !normalized.isEmpty else {
            return
        }

        for index in prompts.indices {
            prompts[index].tags.removeAll {
                $0.caseInsensitiveCompare(normalized) == .orderedSame
            }
        }
        definedTags.removeAll {
            $0.caseInsensitiveCompare(normalized) == .orderedSame
        }
        save()
    }

    func usageCount(for tag: String) -> Int {
        prompts.filter { prompt in
            prompt.tags.contains {
                $0.caseInsensitiveCompare(tag) == .orderedSame
            }
        }.count
    }

    static func preview() -> PromptStore {
        let store = PromptStore()
        store.prompts = [
            Prompt(
                title: "论文阅读总结",
                content: "请用 5 个要点总结这篇论文，并给出方法、实验和局限。",
                tags: ["看论文", "总结"],
                isFavorite: true,
                createdAt: .now,
                updatedAt: .now,
                lastUsedAt: .now,
                usageCount: 6
            ),
            Prompt(
                title: "重构建议",
                content: "请识别这段代码中的设计味道，并给出可落地的重构步骤。",
                tags: ["写代码", "看代码"],
                createdAt: .now,
                updatedAt: .now,
                usageCount: 3
            )
        ]
        store.definedTags = ["看论文", "总结", "写代码", "看代码"]
        return store
    }
}

private extension PromptStore {
    var storageURL: URL {
        let baseURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return baseURL
            .appendingPathComponent("PromptManager", isDirectory: true)
            .appendingPathComponent("prompts.json")
    }

    func load() {
        do {
            let fileURL = storageURL
            if !fileManager.fileExists(atPath: fileURL.path) {
                try createStorageDirectoryIfNeeded()
                return
            }
            let data = try Data(contentsOf: fileURL)
            let snapshot = try decoder.decode(PromptLibrarySnapshot.self, from: data)
            prompts = snapshot.prompts
            definedTags = uniqueCaseInsensitive(snapshot.definedTags + prompts.flatMap(\.tags))
        } catch {
            prompts = []
            definedTags = []
            print("PromptStore load error: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            try createStorageDirectoryIfNeeded()
            let snapshot = PromptLibrarySnapshot(
                prompts: prompts,
                definedTags: uniqueCaseInsensitive(definedTags + prompts.flatMap(\.tags))
            )
            let data = try encoder.encode(snapshot)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("PromptStore save error: \(error.localizedDescription)")
        }
    }

    func createStorageDirectoryIfNeeded() throws {
        let directory = storageURL.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    func register(tags: [String]) {
        definedTags = uniqueCaseInsensitive(definedTags + tags)
    }

    func removeUnusedDefinedTags() {
        let allTagsInPrompts = Set(prompts.flatMap(\.tags).map { $0.lowercased() })
        definedTags.removeAll { !allTagsInPrompts.contains($0.lowercased()) }
    }

    func normalizeTags(from rawTags: String) -> [String] {
        let candidates = rawTags
            .split(separator: ",")
            .map { String($0) }
            .map(normalizeSingleTag)
            .filter { !$0.isEmpty }
        return uniquePreservingOrder(candidates)
    }

    func normalizeSingleTag(_ rawTag: String) -> String {
        rawTag.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func uniquePreservingOrder(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for tag in tags {
            let lower = tag.lowercased()
            if seen.insert(lower).inserted {
                result.append(tag)
            }
        }
        return result
    }

    func uniqueCaseInsensitive(_ tags: [String]) -> [String] {
        var existing = Set<String>()
        var result: [String] = []
        for tag in tags {
            let normalized = normalizeSingleTag(tag)
            guard !normalized.isEmpty else { continue }
            if existing.insert(normalized.lowercased()).inserted {
                result.append(normalized)
            }
        }
        return result
    }

    func sortPrompts(_ lhs: Prompt, _ rhs: Prompt) -> Bool {
        if lhs.isFavorite != rhs.isFavorite {
            return lhs.isFavorite && !rhs.isFavorite
        }
        let lhsDate = lhs.lastUsedAt ?? lhs.updatedAt
        let rhsDate = rhs.lastUsedAt ?? rhs.updatedAt
        if lhsDate != rhsDate {
            return lhsDate > rhsDate
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }

    func copyToClipboard(_ text: String) {
#if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#elseif os(iOS)
        UIPasteboard.general.string = text
#endif
    }

    func showToast(_ message: String) {
        copyToastMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.4))
            if copyToastMessage == message {
                copyToastMessage = nil
            }
        }
    }
}
