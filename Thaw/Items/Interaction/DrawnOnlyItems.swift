//
//  DrawnOnlyItems.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import MenuBarModel
import Synchronization
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

    /// How a pass records an owner whose empty answer waited on the drawn read.
    enum Answer: Equatable, Sendable {
        case record([RawItem])
        /// The drawn read was taken mid-change, so the owner's last answer stands and the pass is incomplete.
        case keepPrior
    }

    /// What one pass knows besides the drawn read.
    struct Pass: Sendable {
        let apps: [pid_t: App]
        /// This app's pid, MenuBarAgent's and the control pids.
        let excluded: Set<pid_t>
        /// The items the AX walk read this pass.
        let axItems: [RawItem]
        /// The tallest frame that still counts as a status item.
        let ceiling: CGFloat
    }

    /// The result of settling a pass's waiting owners.
    struct Resolution: Equatable, Sendable {
        let answers: [pid_t: Answer]
        let newlyConfirmed: Set<pid_t>
        let newlySkipped: Set<pid_t>
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

    /// Settles the owners whose empty answer waited on the drawn read.
    ///
    /// A settled read records the synthesized item for each confirmed owner and nothing for the rest.
    /// A nil read, taken mid-change, keeps every waiting owner's last answer and guesses nothing.
    static func resolve(
        pending: Set<pid_t>,
        read: [Entry]?,
        pass: Pass,
        ledger: DrawnOnlyOwnerLedger,
        now: ContinuousClock.Instant = .now
    ) -> Resolution {
        guard let read else {
            return Resolution(answers: pending.reduce(into: [:]) { $0[$1] = .keepPrior }, newlyConfirmed: [], newlySkipped: [])
        }
        let selection = silentDrawnOwners(
            entries: read, answeredEmpty: pending, excluded: pass.excluded, apps: pass.apps, axItems: pass.axItems
        )
        let confirmation = ledger.confirm(
            silent: Set(selection.owners.keys),
            answered: pending.union(pass.axItems.map(\.ownerPID)),
            running: Set(pass.apps.keys),
            now: now
        )
        let band = band(of: pass.axItems)
        var answers: [pid_t: Answer] = [:]
        for owner in pending {
            guard confirmation.confirmed.contains(owner), let entry = selection.owners[owner], let app = pass.apps[owner],
                  let item = rawItem(
                      ownerPID: owner, app: app, frame: normalizedFrame(entry: entry.frame, band: band, ceiling: pass.ceiling)
                  )
            else {
                answers[owner] = .record([])
                continue
            }
            answers[owner] = .record([item])
        }
        return Resolution(
            answers: answers,
            newlyConfirmed: confirmation.newlyConfirmed,
            newlySkipped: ledger.firstSkips(of: selection.multiEntryOwners)
        )
    }
}

/// Owners found drawn and silent, and since when.
///
/// An owner must stay drawn and silent for the confirmation delay before its item is synthesized, so
/// an app that publishes its items a moment after drawing them is read the normal way. An owner that
/// answers with items, or is no longer drawn, leaves; one that quits is dropped.
nonisolated final class DrawnOnlyOwnerLedger: Sendable {
    static let confirmationDelay = Duration.seconds(2)

    struct Confirmation: Equatable, Sendable {
        let confirmed: Set<pid_t>
        let newlyConfirmed: Set<pid_t>
    }

    private struct State {
        var silentSince: [pid_t: ContinuousClock.Instant] = [:]
        var confirmed: Set<pid_t> = []
        var skipped: Set<pid_t> = []
    }

    private let state = Mutex(State())

    /// The owners being watched, confirmed or not.
    var owners: Set<pid_t> {
        state.withLock { Set($0.silentSince.keys) }
    }

    /// Records one pass and returns the owners silent for at least the confirmation delay.
    ///
    /// - Parameters:
    ///   - silent: Owners drawn and silent this pass.
    ///   - answered: Owners that answered this pass. Those not silent leave.
    ///   - running: The running pids. Every other owner is dropped.
    func confirm(
        silent: Set<pid_t>,
        answered: Set<pid_t>,
        running: Set<pid_t>,
        now: ContinuousClock.Instant = .now
    ) -> Confirmation {
        state.withLock { state in
            let leaving = answered.subtracting(silent)
            state.silentSince = state.silentSince.filter { running.contains($0.key) && !leaving.contains($0.key) }
            state.skipped.formIntersection(running)
            for owner in silent where state.silentSince[owner] == nil {
                state.silentSince[owner] = now
            }
            let confirmed = Set(silent.filter { owner in
                state.silentSince[owner].map { now - $0 >= Self.confirmationDelay } == true
            })
            let newlyConfirmed = confirmed.subtracting(state.confirmed)
            state.confirmed = state.confirmed.intersection(state.silentSince.keys).union(confirmed)
            return Confirmation(confirmed: confirmed, newlyConfirmed: newlyConfirmed)
        }
    }

    /// The owners among skipped not reported before, so each skip is logged once per process.
    func firstSkips(of skipped: Set<pid_t>) -> Set<pid_t> {
        state.withLock { state in
            let fresh = skipped.subtracting(state.skipped)
            state.skipped.formUnion(fresh)
            return fresh
        }
    }
}
