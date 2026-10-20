//
//  ClickTargetCheck.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import MenuBarModel

/// Whether a freshly read frame is safe to click: mid-reflow a re-read can return a parked or phantom
/// frame, and clicking it hits whatever sits there.
nonisolated enum ClickTargetCheck {
    enum Rejection: String {
        case empty
        /// The leading-edge sentinel macOS 27 reports for a parked item.
        case parked
        /// Below the bar's band, where macOS 27 parks items during a reflow.
        case offBar
        /// Wider than any status item, so it is something else's frame.
        case tooWide
    }

    /// The same limits MenuBarItem.isParkedOffMenuBarBand and the capture band use.
    static let maxBarMidY = MenuBarItem.maxBarBandMidY
    static let maxItemWidth: CGFloat = 200

    static func rejection(for bounds: CGRect) -> Rejection? {
        guard !bounds.isNull, bounds.width.isFinite, bounds.height.isFinite,
              bounds.width > 0, bounds.height > 0
        else { return .empty }
        if bounds.origin.x == -1 { return .parked }
        if bounds.midY > maxBarMidY { return .offBar }
        if bounds.width > maxItemWidth { return .tooWide }
        return nil
    }
}
