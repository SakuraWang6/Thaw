//
//  MenuBarShapePicker.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

import SwiftUI
import ThawUI

/// Picks the shape the menu bar appearance is cut to, how round its corners
/// are, and the margins around it.
///
/// The kinds are drawings, not names: "Split" and "Notch" mean nothing until
/// you see where the bar is cut.
struct MenuBarShapePicker: View {
    @Binding var configuration: MenuBarAppearanceConfigurationV2

    var body: some View {
        kindRow
        if configuration.shapeKind != .noShape {
            cornersRow
            marginsRow
        }
    }

    // MARK: Kind

    private var kindRow: some View {
        HStack(alignment: .top, spacing: ThawSpacing.inset) {
            ForEach(MenuBarShapeKind.allCases) { kind in
                MenuBarShapeKindOption(
                    kind: kind,
                    isSelected: configuration.shapeKind == kind
                ) {
                    configuration.shapeKind = kind
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Shape")
    }

    // MARK: Corners

    /// The info of every part of the shape: one for Full, two for Split and Notch.
    private var parts: [MenuBarFullShapeInfo] {
        switch configuration.shapeKind {
        case .noShape: []
        case .full: [configuration.fullShapeInfo]
        case .split: [configuration.splitShapeInfo.leading, configuration.splitShapeInfo.trailing]
        case .notch: [configuration.notchShapeInfo.leading, configuration.notchShapeInfo.trailing]
        }
    }

    /// One roundness for every end, from square to round. A shape with any
    /// round end reads as its roundness; one with only square ends reads as 0.
    private var roundness: Binding<Double> {
        Binding(
            get: { MenuBarShapeRoundness.value(of: parts) },
            set: { value in
                let info = MenuBarShapeRoundness.info(for: value)
                configuration.fullShapeInfo = info
                configuration.splitShapeInfo = MenuBarSplitShapeInfo(leading: info, trailing: info)
                configuration.notchShapeInfo.leading = info
                configuration.notchShapeInfo.trailing = info
            }
        )
    }

    private var cornersRow: some View {
        LabeledContent("Corners") {
            HStack(spacing: ThawSpacing.base) {
                Text("Square")
                    .font(ThawType.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                ThawSlider(value: roundness, in: 0 ... 1) {
                    EmptyView()
                }
                .accessibilityLabel("Corners")
                Text("Round")
                    .font(ThawType.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: 360)
        }
    }

    // MARK: Margins

    private var marginsRow: some View {
        LabeledContent("Margins") {
            HStack(spacing: ThawSpacing.base) {
                margin("Left", value: $configuration.leftMargin)
                if configuration.shapeKind == .notch {
                    margin("Notch", value: $configuration.notchMargin)
                }
                margin("Right", value: $configuration.rightMargin, reversed: true)
            }
            .frame(maxWidth: 360)
        }
    }

    private func margin(_ label: LocalizedStringKey, value: Binding<Double>, reversed: Bool = false) -> some View {
        ThawSlider(label, value: value, in: 0 ... 15, step: 1, reversed: reversed, showsValue: true, unit: "pt")
    }
}

/// Reads and writes the Corners slider as end caps and a roundness.
nonisolated enum MenuBarShapeRoundness {
    /// The slider's value for a shape made of these parts.
    static func value(of parts: [MenuBarFullShapeInfo]) -> Double {
        let rounded = parts.filter { $0.leadingEndCap == .round || $0.trailingEndCap == .round }
        return rounded.map(\.roundness).max() ?? 0
    }

    /// The part every end gets for a slider value: square ends at 0, round
    /// ends curved by the value above it.
    static func info(for value: Double) -> MenuBarFullShapeInfo {
        let value = min(max(value, 0), 1)
        let cap: MenuBarEndCap = value > 0 ? .round : .square
        return MenuBarFullShapeInfo(leadingEndCap: cap, trailingEndCap: cap, roundness: value)
    }
}

/// One shape kind: a drawing of a menu bar with the shape on it, and its name.
private struct MenuBarShapeKindOption: View {
    let kind: MenuBarShapeKind
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: ThawSpacing.tight) {
                MenuBarShapeKindDrawing(kind: kind)
                    .frame(width: 64, height: 18)
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(isHovered ? .primary : .secondary))
                Text(kind.localized)
                    .font(ThawType.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(ThawSpacing.tight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(Text(kind.localized))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .help(Text(kind.caption))
    }
}

/// A menu bar in outline, with the shape filled in. Drawn with Canvas so a
/// 1 pt outline lands on the pixel grid at this size.
private struct MenuBarShapeKindDrawing: View {
    let kind: MenuBarShapeKind

    var body: some View {
        Canvas { context, size in
            let bar = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
            let outline = Path(roundedRect: bar, cornerRadius: 3, style: .continuous)
            let inset: CGFloat = 3
            let pillHeight = size.height - inset * 2
            func pill(_ minX: CGFloat, _ width: CGFloat) -> Path {
                Path(
                    roundedRect: CGRect(x: minX, y: inset, width: width, height: pillHeight),
                    cornerRadius: pillHeight / 2,
                    style: .continuous
                )
            }

            switch kind {
            case .noShape:
                // The look covers the whole bar.
                context.fill(outline, with: .foreground)
            case .full:
                context.stroke(outline, with: .foreground, lineWidth: 1)
                context.fill(pill(inset, size.width - inset * 2), with: .foreground)
            case .split:
                context.stroke(outline, with: .foreground, lineWidth: 1)
                context.fill(pill(inset, size.width * 0.34), with: .foreground)
                let trailingWidth = size.width * 0.42
                context.fill(pill(size.width - inset - trailingWidth, trailingWidth), with: .foreground)
            case .notch:
                context.stroke(outline, with: .foreground, lineWidth: 1)
                let notchWidth = size.width * 0.18
                let notch = CGRect(x: (size.width - notchWidth) / 2, y: 0, width: notchWidth, height: size.height * 0.7)
                context.fill(
                    Path(roundedRect: notch, cornerRadius: 2, style: .continuous),
                    with: .foreground
                )
                let sideWidth = (size.width - notchWidth) / 2 - inset * 2
                context.fill(pill(inset, sideWidth), with: .foreground)
                context.fill(pill(size.width - inset - sideWidth, sideWidth), with: .foreground)
            }
        }
        .accessibilityHidden(true)
    }
}
