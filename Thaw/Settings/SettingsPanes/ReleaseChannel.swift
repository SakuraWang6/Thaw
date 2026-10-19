//
//  ReleaseChannel.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import SwiftUI

/// The update channel a release belongs to, read from its version: a
/// pre-release tag of alpha is Alpha, beta or rc is Beta, and no tag is
/// Stable. What's New lists one channel at a time.
nonisolated enum ReleaseChannel: String, CaseIterable, Identifiable {
    case stable
    case beta
    case alpha

    var id: Self {
        self
    }

    init(version: String) {
        let tag = version.split(separator: "-", maxSplits: 1).dropFirst().first?.lowercased() ?? ""
        if tag.hasPrefix("alpha") {
            self = .alpha
        } else if tag.isEmpty {
            self = .stable
        } else {
            self = .beta
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .stable: "Stable"
        case .beta: "Beta"
        case .alpha: "Alpha"
        }
    }

    /// The channel to open on: the update waiting to install, else the build
    /// that is running, so the newest notes for this Mac come first.
    static func initial(pendingUpdate: String?, running: String) -> ReleaseChannel {
        ReleaseChannel(version: pendingUpdate ?? running)
    }
}
