//
//  BackdropRefreshCadenceTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import CoreGraphics
import Testing
@testable import Thaw

@Suite("Backdrop refresh cadence")
struct BackdropRefreshCadenceTests {
    @Test("Fast while a cover is likely, slow otherwise")
    func fastAndSlow() {
        #expect(BackdropRefreshCadence.nextInterval(coverLikely: true, screenLocked: false, idleSeconds: 1) == BackdropRefreshCadence.fast)
        #expect(BackdropRefreshCadence.nextInterval(coverLikely: false, screenLocked: false, idleSeconds: 1) == BackdropRefreshCadence.slow)
    }

    @Test("Paused while the screen is locked or nobody has touched the Mac for a while")
    func paused() {
        #expect(BackdropRefreshCadence.nextInterval(coverLikely: true, screenLocked: true, idleSeconds: 1) == nil)
        #expect(BackdropRefreshCadence.nextInterval(coverLikely: true, screenLocked: false, idleSeconds: BackdropRefreshCadence.idleThreshold) == nil)
    }

    @Test("A window that moves under the bar changes the key, and so do the same windows stacked in another order")
    func keyFollowsWindowPlaces() {
        let rect = CGRect(x: 0, y: 0, width: 1920, height: 30)
        let before = MenuBarBackdrop.stripKey(rect: rect, windows: [(7, CGRect(x: 0, y: 0, width: 400, height: 300)), (3, .zero)])
        let reordered = MenuBarBackdrop.stripKey(rect: rect, windows: [(3, .zero), (7, CGRect(x: 0, y: 0, width: 400, height: 300))])
        let moved = MenuBarBackdrop.stripKey(rect: rect, windows: [(7, CGRect(x: 200, y: 0, width: 400, height: 300)), (3, .zero)])
        #expect(before != reordered)
        #expect(before != moved)
        #expect(before == MenuBarBackdrop.stripKey(rect: rect, windows: [(7, CGRect(x: 0, y: 0, width: 400, height: 300)), (3, .zero)]))
    }
}
