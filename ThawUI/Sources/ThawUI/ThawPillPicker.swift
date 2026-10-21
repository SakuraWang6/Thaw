//
//  ThawPillPicker.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import SwiftUI

/// A few choices in one glass capsule, each as wide as its label, like the toggles
/// in Xcode's toolbar. It sits in a row beside its label, where ThawTabStrip would
/// fill the page. With symbols and no titles it is an icon toggle, and the titles
/// stay on as help and for VoiceOver.
public struct ThawPillPicker<Value: Hashable>: View {
    public struct Option {
        let value: Value
        let title: LocalizedStringKey
        let systemImage: String?
        let help: LocalizedStringKey?

        public init(_ value: Value, title: LocalizedStringKey, systemImage: String? = nil, help: LocalizedStringKey? = nil) {
            self.value = value
            self.title = title
            self.systemImage = systemImage
            self.help = help
        }
    }

    @Binding private var selection: Value
    private let options: [Option]
    private let showsTitles: Bool

    public init(selection: Binding<Value>, options: [Option], showsTitles: Bool = true) {
        _selection = selection
        self.options = options
        self.showsTitles = showsTitles
    }

    public var body: some View {
        ThawCapsuleSegments(
            selection: $selection,
            segments: options.map { option in
                .init(value: option.value, title: option.title, systemImage: option.systemImage, help: option.help ?? option.title)
            },
            sizing: .fitted(showsTitles: showsTitles)
        )
    }
}
