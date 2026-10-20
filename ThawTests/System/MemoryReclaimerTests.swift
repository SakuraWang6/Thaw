//
//  MemoryReclaimerTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Testing
@testable import Thaw

struct MemoryReclaimerTests {
    @Test
    func `the footprint warning fires once, when Thaw first passes the line`() {
        #expect(!MemoryReclaimer.shouldWarn(megabytes: 40, alreadyWarned: false))
        #expect(MemoryReclaimer.shouldWarn(megabytes: 151, alreadyWarned: false))
        #expect(!MemoryReclaimer.shouldWarn(megabytes: 500, alreadyWarned: true))
    }

    @Test
    func `the footprint can be read`() {
        #expect((MemoryReclaimer.physicalFootprint() ?? 0) > 0)
    }
}
