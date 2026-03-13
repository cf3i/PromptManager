//
//  Prompt.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import Foundation

struct Prompt: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String]
    var isFavorite: Bool
    let createdAt: Date
    var updatedAt: Date
    var lastUsedAt: Date?
    var usageCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        tags: [String],
        isFavorite: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        lastUsedAt: Date? = nil,
        usageCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsedAt = lastUsedAt
        self.usageCount = usageCount
    }
}

struct PromptDraft {
    var title: String
    var content: String
    var tags: String
    var isFavorite: Bool

    init(title: String = "", content: String = "", tags: String = "", isFavorite: Bool = false) {
        self.title = title
        self.content = content
        self.tags = tags
        self.isFavorite = isFavorite
    }
}

struct PromptLibrarySnapshot: Codable {
    var prompts: [Prompt]
    var definedTags: [String]
}
