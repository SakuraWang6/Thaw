//
//  ArrayNeighborTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Testing
@testable import Thaw

@Suite("Array neighbor")
struct ArrayNeighborTests {
    @Test("The arrow keys step to the next or previous element and stop at the ends")
    func stepsAndStops() {
        let list = ["a", "b", "c"]
        #expect(list.neighbor(of: "b", by: 1) == "c")
        #expect(list.neighbor(of: "b", by: -1) == "a")
        #expect(list.neighbor(of: "a", by: -1) == nil)
        #expect(list.neighbor(of: "c", by: 1) == nil)
        #expect(list.neighbor(of: "z", by: 1) == nil)
    }
}
