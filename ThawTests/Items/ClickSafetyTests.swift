//
//  ClickSafetyTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import Foundation
import Testing
@testable import Thaw

struct ClickSafetyTests {
    @Test
    func `a seated item frame is clicked`() {
        #expect(ClickTargetCheck.rejection(for: CGRect(x: 1400, y: 0, width: 24, height: 30)) == nil)
    }

    @Test
    func `parked, off-bar, empty and too-wide frames are refused`() {
        #expect(ClickTargetCheck.rejection(for: CGRect(x: -1, y: 0, width: 24, height: 30)) == .parked)
        #expect(ClickTargetCheck.rejection(for: CGRect(x: 7, y: 1068, width: 24, height: 30)) == .offBar)
        #expect(ClickTargetCheck.rejection(for: .zero) == .empty)
        #expect(ClickTargetCheck.rejection(for: .null) == .empty)
        #expect(ClickTargetCheck.rejection(for: CGRect(x: 0, y: 0, width: 600, height: 30)) == .tooWide)
    }

    @Test
    func `the budget allows a burst of clicks, then refuses until the window passes`() {
        var budget = SyntheticClickBudget()
        let start = ContinuousClock.now
        for offset in 0 ..< SyntheticClickBudget.limit {
            let taken = budget.take(now: start + .milliseconds(offset))
            #expect(taken)
        }
        let overBudget = budget.take(now: start + .seconds(1))
        #expect(!overBudget)
        let afterWindow = budget.take(now: start + SyntheticClickBudget.window + .milliseconds(1))
        #expect(afterWindow)
    }
}
