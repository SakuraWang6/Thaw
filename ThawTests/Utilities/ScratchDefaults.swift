//
//  ScratchDefaults.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Foundation
@testable import Thaw

/// Removing a throwaway suite's domain leaves an empty plist in ~/Library/Preferences, so this deletes the file too.
/// Main actor only, since removing a domain posts a defaults change the app observes on the main thread.
@MainActor
enum ScratchDefaults {
    static func remove(_ name: String) {
        UserDefaults.standard.removePersistentDomain(forName: name)
        CFPreferencesAppSynchronize(name as CFString)
        try? FileManager.default.removeItem(at: URL.libraryDirectory.appending(path: "Preferences/\(name).plist"))
    }

    /// Runs body with Defaults reading and writing a throwaway suite, then
    /// puts the real store back and deletes the suite.
    static func withStore(named prefix: String, _ body: (UserDefaults) throws -> Void) throws {
        let name = "\(prefix).\(UUID().uuidString)"
        guard let store = UserDefaults(suiteName: name) else {
            throw CocoaError(.featureUnsupported)
        }
        let previous = Defaults.store
        Defaults.store = store
        defer {
            Defaults.store = previous
            remove(name)
        }
        try body(store)
    }
}

/// Throwaway suites made for one test, removed when the test lets go of them.
@MainActor
final class ScratchSuites {
    private let prefix: String
    private var names = [String]()

    init(prefix: String) {
        self.prefix = prefix
    }

    isolated deinit {
        names.forEach(ScratchDefaults.remove)
    }

    func make() -> UserDefaults? {
        let name = "\(prefix).\(UUID().uuidString)"
        names.append(name)
        return UserDefaults(suiteName: name)
    }
}
