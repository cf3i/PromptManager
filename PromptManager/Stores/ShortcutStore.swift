//
//  ShortcutStore.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ShortcutStore: ObservableObject {
    static let shared = ShortcutStore()

    @Published private(set) var shortcuts: [ShortcutAction: ShortcutDefinition]
    @Published var validationMessage: String?

    private let defaults: UserDefaults
    private let storageKey = "promptManager.shortcuts.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.shortcuts = ShortcutStore.loadShortcuts(defaults: defaults) ?? ShortcutStore.defaultShortcuts
    }

    func shortcut(for action: ShortcutAction) -> ShortcutDefinition {
        shortcuts[action] ?? action.defaultShortcut
    }

    func binding(for action: ShortcutAction) -> Binding<ShortcutDefinition> {
        Binding(
            get: { self.shortcut(for: action) },
            set: { self.updateShortcut(for: action, to: $0) }
        )
    }

    func updateShortcut(for action: ShortcutAction, to newValue: ShortcutDefinition) {
        var candidate = shortcuts
        candidate[action] = newValue

        guard newValue.hasModifier else {
            presentValidation("Shortcut for \(action.title) needs at least one modifier.")
            return
        }
        guard isUnique(candidate) else {
            presentValidation("Shortcut conflict detected. Please use different combinations.")
            return
        }

        shortcuts = candidate
        save()
    }

    func resetDefaults() {
        shortcuts = ShortcutStore.defaultShortcuts
        save()
    }

    var quickAddDisplay: String {
        shortcut(for: .quickAdd).displayText
    }

    var quickPickerDisplay: String {
        shortcut(for: .quickPicker).displayText
    }

    func presentValidation(_ message: String, duration: Duration = .seconds(2)) {
        publishValidation(message, duration: duration)
    }
}

private extension ShortcutStore {
    struct ShortcutPayload: Codable {
        var quickAdd: ShortcutDefinition
        var quickPicker: ShortcutDefinition
    }

    static var defaultShortcuts: [ShortcutAction: ShortcutDefinition] {
        Dictionary(
            uniqueKeysWithValues: ShortcutAction.allCases.map { action in
                (action, action.defaultShortcut)
            }
        )
    }

    static func loadShortcuts(defaults: UserDefaults) -> [ShortcutAction: ShortcutDefinition]? {
        guard let data = defaults.data(forKey: "promptManager.shortcuts.v1") else {
            return nil
        }
        do {
            let decoded = try JSONDecoder().decode(ShortcutPayload.self, from: data)
            return [
                .quickAdd: decoded.quickAdd,
                .quickPicker: decoded.quickPicker
            ]
        } catch {
            return nil
        }
    }

    func save() {
        do {
            let payload = ShortcutPayload(
                quickAdd: shortcut(for: .quickAdd),
                quickPicker: shortcut(for: .quickPicker)
            )
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: storageKey)
        } catch {
            publishValidation("Failed to save shortcuts.", duration: .seconds(2))
        }
    }

    func isUnique(_ values: [ShortcutAction: ShortcutDefinition]) -> Bool {
        var seen = Set<String>()
        for shortcut in values.values {
            let fingerprint = [
                shortcut.key.rawValue,
                shortcut.command.description,
                shortcut.option.description,
                shortcut.shift.description,
                shortcut.control.description
            ].joined(separator: "|")
            if !seen.insert(fingerprint).inserted {
                return false
            }
        }
        return true
    }

    func publishValidation(_ message: String, duration: Duration) {
        validationMessage = message
        Task { @MainActor in
            try? await Task.sleep(for: duration)
            if validationMessage == message {
                validationMessage = nil
            }
        }
    }
}
