//
//  NativeHidingStartTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Testing
@testable import Thaw

@MainActor
@Suite("A failed start of native hiding does not lose the user's choice")
struct NativeHidingStartTests {
    @Test("A start that fails at launch keeps the choice")
    func launchFailureKeepsTheChoice() {
        #expect(NativeHidingStart.keepsChoice(afterFailedStartAtLaunch: true))
    }

    @Test("A start the user just asked for goes back to off when it fails")
    func userStartFailureTurnsItOff() {
        #expect(!NativeHidingStart.keepsChoice(afterFailedStartAtLaunch: false))
    }

    @Test("A failed start says why, or that macOS gave no reason")
    func failureNoticeSaysWhy() {
        let reason = "Thaw can't read Control Center's settings."
        #expect(NativeHidingStart.failureNotice(reason: reason).hasSuffix(reason))
        #expect(NativeHidingStart.failureNotice(reason: nil).hasSuffix("macOS gave no reason."))
        #expect(NativeHidingStart.failureNotice(reason: nil).contains("using Standard"))
    }
}
