//
//  SimpleRehideChoiceTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Foundation
import Testing
@testable import Thaw

@Suite("Simple Mode's Hide items again menu")
struct SimpleRehideChoiceTests {
    @Test("Each saved combination reads as one choice")
    func readsSettings() {
        #expect(SimpleRehideChoice(autoRehide: false, strategy: .timed, interval: 10) == .never)
        #expect(SimpleRehideChoice(autoRehide: true, strategy: .smart, interval: 10) == .whenClickingElsewhere)
        #expect(SimpleRehideChoice(autoRehide: true, strategy: .focusedApp, interval: 10) == .whenSwitchingApps)
        #expect(SimpleRehideChoice(autoRehide: true, strategy: .timed, interval: 30) == .after(30))
    }

    @Test("Choosing writes back what the full window shows")
    func writesSettings() {
        #expect(SimpleRehideChoice.never.settings(keepingInterval: 15) == (false, nil, 15))
        #expect(SimpleRehideChoice.whenClickingElsewhere.settings(keepingInterval: 15) == (true, .smart, 15))
        #expect(SimpleRehideChoice.after(60).settings(keepingInterval: 15) == (true, .timed, 60))
    }

    @Test("A delay set in the full window that isn't listed still shows in the menu")
    func keepsAnUnlistedDelay() {
        let options = SimpleRehideChoice.options(including: .after(42))
        #expect(options.last == .after(42))
        #expect(SimpleRehideChoice.options(including: .after(30)).count == 8)
    }
}
