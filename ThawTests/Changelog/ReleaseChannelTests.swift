//
//  ReleaseChannelTests.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import Testing
@testable import Thaw

@Suite("What's New channels")
struct ReleaseChannelTests {
    @Test("A version's tag picks its channel", arguments: [
        ("3.0.0-alpha.11", ReleaseChannel.alpha),
        ("3.0.0-alpha.4.1", .alpha),
        ("3.0.0-beta.3", .beta),
        ("2.0.1-rc.2", .beta),
        ("3.0.0", .stable),
        ("3.1.0", .stable),
    ])
    func channelFromVersion(version: String, channel: ReleaseChannel) {
        #expect(ReleaseChannel(version: version) == channel)
    }

    @Test("What's New opens on the waiting update's channel, else the running build's")
    func initialChannel() {
        #expect(ReleaseChannel.initial(pendingUpdate: "3.0.0-beta.3", running: "3.0.0-alpha.11") == .beta)
        #expect(ReleaseChannel.initial(pendingUpdate: nil, running: "3.0.0-alpha.11") == .alpha)
        #expect(ReleaseChannel.initial(pendingUpdate: nil, running: "3.0.0") == .stable)
    }

    @Test("Each channel keeps its own releases in file order")
    @MainActor
    func splitsReleases() {
        let document = ChangelogDocument.parse("""
        ## [3.0.0-alpha.11] - 2026-10-19

        - Alpha.

        ## [3.0.0-beta.3] - 2026-10-19

        - Beta.

        ## [3.0.0-alpha.10] - 2026-10-18

        - Older alpha.
        """)
        let releases = ChangelogDocument.displayReleases(in: document)
        let alpha = releases.filter { ReleaseChannel(version: $0.version) == .alpha }.map(\.version)
        let beta = releases.filter { ReleaseChannel(version: $0.version) == .beta }.map(\.version)
        #expect(alpha == ["3.0.0-alpha.11", "3.0.0-alpha.10"])
        #expect(beta == ["3.0.0-beta.3"])
        #expect(!releases.contains { ReleaseChannel(version: $0.version) == .stable })
    }
}
