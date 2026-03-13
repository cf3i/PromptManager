//
//  MacIntegration.swift
//  PromptManager
//
//  Created by Codex on 13/03/2026.
//

#if os(macOS)
import SwiftUI
import AppKit
import Carbon.HIToolbox
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var isConfigured = false
    private var shortcutObserver: AnyCancellable?
    private var shortcutStore: ShortcutStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        configure(with: PromptStore.shared, shortcutStore: ShortcutStore.shared)
    }

    func configure(with store: PromptStore, shortcutStore: ShortcutStore) {
        guard !isConfigured else { return }
        isConfigured = true
        self.shortcutStore = shortcutStore

        QuickAddWindowController.shared.configure(store: store)
        QuickPickerWindowController.shared.configure(store: store)
        ShortcutSettingsWindowController.shared.configure(shortcutStore: shortcutStore)
        GlobalHotKeyManager.shared.configureHandlers(
            quickPicker: {
                QuickPickerWindowController.shared.toggle()
            },
            quickAdd: {
                AppActions.requestQuickAdd()
            }
        )
        registerHotKeys(with: shortcutStore.shortcuts)

        shortcutObserver = shortcutStore.$shortcuts.sink { [weak self] newValues in
            self?.registerHotKeys(with: newValues)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        shortcutObserver?.cancel()
        GlobalHotKeyManager.shared.unregisterAll()
    }

    private func registerHotKeys(with shortcuts: [ShortcutAction: ShortcutDefinition]) {
        let quickPicker = shortcuts[.quickPicker] ?? ShortcutAction.quickPicker.defaultShortcut
        let quickAdd = shortcuts[.quickAdd] ?? ShortcutAction.quickAdd.defaultShortcut
        let result = GlobalHotKeyManager.shared.registerHotKeys(
            quickPicker: quickPicker,
            quickAdd: quickAdd
        )
        if result.quickPicker != noErr {
            shortcutStore?.presentValidation(
                registrationMessage(for: .quickPicker, status: result.quickPicker),
                duration: .seconds(4)
            )
        }
        if result.quickAdd != noErr {
            shortcutStore?.presentValidation(
                registrationMessage(for: .quickAdd, status: result.quickAdd),
                duration: .seconds(4)
            )
        }
    }

    private func registrationMessage(for action: ShortcutAction, status: OSStatus) -> String {
        if status == eventHotKeyExistsErr {
            return "\(action.title) shortcut is already used by macOS or another app."
        }
        return "Failed to register \(action.title) shortcut (code \(status))."
    }
}

final class QuickAddWindowController: NSObject {
    static let shared = QuickAddWindowController()

    private var store: PromptStore?
    private var window: NSWindow?

    func configure(store: PromptStore) {
        self.store = store
    }

    func show() {
        guard window != nil || store != nil else { return }
        if window == nil {
            createWindowIfNeeded()
        }
        refreshContentIfPossible()

        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func createWindowIfNeeded() {
        guard window == nil else { return }

        let createdWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        createdWindow.title = "Quick Add"
        createdWindow.isReleasedWhenClosed = false

        window = createdWindow
    }

    private func refreshContentIfPossible() {
        guard let window, let store else { return }

        let quickAddView = QuickAddPromptView(
            onSave: { [weak self] draft in
                store.createPrompt(from: draft)
                self?.hide()
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )
        .environmentObject(store)

        window.contentViewController = NSHostingController(rootView: quickAddView)
    }
}

final class ShortcutSettingsWindowController: NSObject {
    static let shared = ShortcutSettingsWindowController()

    private var shortcutStore: ShortcutStore?
    private var window: NSWindow?

    func configure(shortcutStore: ShortcutStore) {
        self.shortcutStore = shortcutStore
    }

    func show() {
        guard window != nil || shortcutStore != nil else { return }
        if window == nil {
            createWindowIfNeeded()
        }
        refreshContentIfPossible()

        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    private func createWindowIfNeeded() {
        guard window == nil else { return }

        let createdWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        createdWindow.title = "Shortcut Settings"
        createdWindow.isReleasedWhenClosed = false

        window = createdWindow
    }

    private func refreshContentIfPossible() {
        guard let window else { return }
        let shortcutStore = self.shortcutStore ?? ShortcutStore.shared
        let settingsView = ShortcutSettingsView()
            .environmentObject(shortcutStore)
        window.contentViewController = NSHostingController(rootView: settingsView)
    }
}

final class QuickPickerWindowController: NSObject {
    static let shared = QuickPickerWindowController()

    private var store: PromptStore?
    private var panel: NSPanel?

    func configure(store: PromptStore) {
        self.store = store
    }

    func toggle() {
        if panel?.isVisible == true {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard panel != nil || store != nil else { return }
        if panel == nil {
            createPanelIfNeeded()
        }

        NSApp.activate(ignoringOtherApps: true)
        panel?.center()
        panel?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel?.orderOut(nil)
    }

    private func createPanelIfNeeded() {
        guard panel == nil, let store else { return }

        let pickerView = QuickPickerView(
            store: store,
            onPick: { [weak self] prompt in
                store.copyPrompt(withID: prompt.id)
                self?.hide()
            },
            onClose: { [weak self] in
                self?.hide()
            }
        )

        let hosting = NSHostingController(rootView: pickerView)
        let createdPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 520),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        createdPanel.title = "Quick Picker"
        createdPanel.titleVisibility = .hidden
        createdPanel.titlebarAppearsTransparent = true
        createdPanel.isFloatingPanel = true
        createdPanel.hidesOnDeactivate = true
        createdPanel.level = .floating
        createdPanel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        createdPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        createdPanel.standardWindowButton(.zoomButton)?.isHidden = true
        createdPanel.isReleasedWhenClosed = false
        createdPanel.contentViewController = hosting

        panel = createdPanel
    }
}

final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    private var quickPickerHandler: (() -> Void)?
    private var quickAddHandler: (() -> Void)?

    private var hotKeyRefs: [UInt32: EventHotKeyRef] = [:]
    private var eventHandlerRef: EventHandlerRef?

    private let signature = OSType(0x50524D47) // "PRMG"
    private let quickPickerID: UInt32 = 1
    private let quickAddID: UInt32 = 2

    struct RegistrationResult {
        let quickPicker: OSStatus
        let quickAdd: OSStatus
    }

    func configureHandlers(quickPicker: @escaping () -> Void, quickAdd: @escaping () -> Void) {
        self.quickPickerHandler = quickPicker
        self.quickAddHandler = quickAdd
    }

    @discardableResult
    func registerHotKeys(quickPicker: ShortcutDefinition, quickAdd: ShortcutDefinition) -> RegistrationResult {
        unregisterHotKeys()
        installEventHandlerIfNeeded()

        let quickPickerStatus = registerHotKey(id: quickPickerID, shortcut: quickPicker)
        let quickAddStatus = registerHotKey(id: quickAddID, shortcut: quickAdd)
        return RegistrationResult(quickPicker: quickPickerStatus, quickAdd: quickAddStatus)
    }

    func unregisterAll() {
        unregisterHotKeys()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    private func registerHotKey(id: UInt32, shortcut: ShortcutDefinition) -> OSStatus {
        let eventHotKeyID = EventHotKeyID(signature: signature, id: id)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.key.carbonKeyCode,
            shortcut.carbonModifiers,
            eventHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if status == noErr, let hotKeyRef {
            hotKeyRefs[id] = hotKeyRef
        }
        return status
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else {
            return
        }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, eventRef, userData in
                guard let eventRef, let userData else {
                    return noErr
                }
                let manager = Unmanaged<GlobalHotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                var pressedHotKeyID = EventHotKeyID()
                GetEventParameter(
                    eventRef,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressedHotKeyID
                )

                guard pressedHotKeyID.signature == manager.signature else {
                    return noErr
                }
                DispatchQueue.main.async {
                    if pressedHotKeyID.id == manager.quickPickerID {
                        manager.quickPickerHandler?()
                    } else if pressedHotKeyID.id == manager.quickAddID {
                        manager.quickAddHandler?()
                    }
                }
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandlerRef
        )
    }

    private func unregisterHotKeys() {
        for hotKeyRef in hotKeyRefs.values {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs = [:]
    }
}
#endif
