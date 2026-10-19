//
//  Array+Neighbor.swift
//  Project: Thaw
//
//  Copyright (Thaw) © 2026 Toni Förster
//  Licensed under the GNU GPLv3

nonisolated extension Array where Element: Equatable {
    /// The element offset places away from element, as the arrow keys step
    /// through a list: nil when element isn't here or the step would leave
    /// the list.
    func neighbor(of element: Element, by offset: Int) -> Element? {
        guard let index = firstIndex(of: element), indices.contains(index + offset) else { return nil }
        return self[index + offset]
    }
}
