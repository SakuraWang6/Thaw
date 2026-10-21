//
//  HIDEventManager+HoverPause.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import AppKit

extension HIDEventManager {
    /// Suppresses show-on-hover after a press in the menu bar, until the
    /// pointer leaves and hovering is allowed again.
    func handlePreventShowOnHover(
        with event: NSEvent,
        appState: AppState,
        screen: NSScreen
    ) {
        guard
            configuration.showOnHover,
            !appState.menuBarManager.shouldUseThawBar(for: screen.displayID)
        else {
            return
        }

        guard isMouseInsideMenuBar(appState: appState, screen: screen) else {
            return
        }

        guard shouldPreventShowOnHover(for: event, appState: appState, screen: screen) else {
            return
        }

        if appState.menuBarManager.showOnHoverAllowed {
            Self.diagLog.debug("hover: a press in the menu bar pauses it until the pointer leaves")
        }
        appState.menuBarManager.showOnHoverAllowed = false
    }

    /// Empty-space presses suppress hover; item presses do so when a section is revealed or Thaw's icon is pressed.
    private func shouldPreventShowOnHover(
        for event: NSEvent,
        appState: AppState,
        screen: NSScreen
    ) -> Bool {
        guard isMouseInsideMenuBarItem(appState: appState, screen: screen) else {
            // Exclude the frontmost app's menu; indeterminate answers count as empty menu bar space.
            return isMouseInsideApplicationMenuClickRegion(
                appState: appState,
                screen: screen
            ) != true
        }
        switch event.type {
        case .leftMouseDown:
            return appState.menuBarManager.hasVisibleSection
                || isMouseInsideThawIcon(appState: appState)
        case .rightMouseDown:
            return appState.menuBarManager.hasVisibleSection
        default:
            return false
        }
    }
}
