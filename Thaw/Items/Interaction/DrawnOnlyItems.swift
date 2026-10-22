//
//  DrawnOnlyItems.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import MenuBarModel
import ThawAXCore

/// Status items that MenuBarAgent's window lists but whose app's own tree does not.
///
/// Some apps answer the walk at once with no extras-bar items while MenuBarAgent draws their icon.
/// For an app with exactly one drawn entry, the walk records the item an untitled extras-bar child of
/// that app would give, so it gets the same tag, the same synthetic window ID and the same position
/// store key. An app with more than one entry is left out, since nothing says which entry is which.
nonisolated enum DrawnOnlyItems {
    typealias Entry = MenuBarAgentWindow.Entry
    typealias RawItem = MenuBarItemAXProvider.RawItem

    /// What the selection needs to know about a running app.
    struct App: Equatable, Sendable {
        let bundleID: String?
        let localizedName: String?
    }

    /// The vertical band this pass's items sit in.
    struct Band: Equatable, Sendable {
        let minY: CGFloat
        let height: CGFloat
    }

    /// The owners a pass found drawn and silent.
    struct Selection: Equatable, Sendable {
        /// Owners with one drawn entry, by pid.
        let owners: [pid_t: Entry]
        /// Owners left out because they have more than one drawn entry.
        let multiEntryOwners: Set<pid_t>
    }

    /// More than this share of an entry's width covered by an AX item means the item is already read.
    static let overlapThreshold: CGFloat = 0.5

    /// The drawn entries whose owner answered this pass with no items and could own a status item.
    ///
    /// An owner qualifies when it answered empty this pass (not skipped, timed out or cooling down),
    /// is not excluded, is a running app with a bundle id outside this app's and MenuBarAgent's
    /// namespaces, and its entry is not mostly covered by an AX item read this pass.
    static func silentDrawnOwners(
        entries: [Entry],
        answeredEmpty: Set<pid_t>,
        excluded: Set<pid_t>,
        apps: [pid_t: App],
        axItems: [RawItem]
    ) -> Selection {
        let grouped = Dictionary(grouping: entries.filter { entry in
            answeredEmpty.contains(entry.ownerPID) && !excluded.contains(entry.ownerPID)
                && apps[entry.ownerPID].map(ownsStatusItems) == true
        }, by: \.ownerPID)
        var owners: [pid_t: Entry] = [:]
        var multiEntryOwners = Set<pid_t>()
        for (owner, ownerEntries) in grouped {
            guard ownerEntries.count == 1, let entry = ownerEntries.first else {
                multiEntryOwners.insert(owner)
                continue
            }
            if !axItems.contains(where: { covers($0.bounds, entry.frame) }) {
                owners[owner] = entry
            }
        }
        return Selection(owners: owners, multiEntryOwners: multiEntryOwners)
    }

    private static func ownsStatusItems(_ app: App) -> Bool {
        guard let bundleID = app.bundleID else { return false }
        let namespace = MenuBarItemAXProvider.namespace(forBundleIdentifier: bundleID, localizedName: app.localizedName)
        return namespace != .thaw && namespace != .menuBarAgent
    }

    /// Whether an item covers more than the threshold of an entry's width on the same row.
    static func covers(_ item: CGRect, _ entry: CGRect) -> Bool {
        guard entry.width > 0, item.minY < entry.maxY, entry.minY < item.maxY else { return false }
        let shared = min(item.maxX, entry.maxX) - max(item.minX, entry.minX)
        return shared > entry.width * overlapThreshold
    }

    /// The item an untitled extras-bar child of the app would give, titled with the app's name.
    static func rawItem(ownerPID: pid_t, app: App, frame: CGRect) -> RawItem? {
        let namespace = MenuBarItemAXProvider.namespace(forBundleIdentifier: app.bundleID, localizedName: app.localizedName)
        guard let item = MenuBarItemAXProvider.rawItem(
            namespace: namespace,
            identifier: nil,
            childIdentifier: nil,
            accessibilityDescription: nil,
            childDescription: nil,
            axTitle: nil,
            fallbackIndex: 0,
            bounds: frame,
            ownerPID: ownerPID
        ).item else { return nil }
        return RawItem(
            namespace: item.namespace,
            identityTitle: item.identityTitle,
            displayTitle: app.localizedName ?? item.displayTitle,
            bounds: frame,
            ownerPID: ownerPID
        )
    }

    /// The median band of this pass's items. MenuBarAgent's own items are left out: its wrappers
    /// span the full bar height.
    static func band(of axItems: [RawItem]) -> Band? {
        let frames = axItems.filter { $0.namespace != .menuBarAgent }.map(\.bounds)
        guard !frames.isEmpty else { return nil }
        return Band(minY: median(frames.map(\.minY)), height: median(frames.map(\.height)))
    }

    private static func median(_ values: [CGFloat]) -> CGFloat {
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }

    /// The entry's frame as an AX item would report it.
    ///
    /// The drawn entry spans the full bar height, so the band of this pass's items gives the
    /// vertical extent. With no band, an entry taller than the ceiling is inset to it, centred.
    static func normalizedFrame(entry: CGRect, band: Band?, ceiling: CGFloat) -> CGRect {
        if let band {
            return CGRect(x: entry.minX, y: band.minY, width: entry.width, height: band.height)
        }
        guard entry.height > ceiling else { return entry }
        return entry.insetBy(dx: 0, dy: (entry.height - ceiling) / 2)
    }
}
