//
//  Array+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 01/12/24.
//

import Foundation

public extension Array {
    /// Returns the element at the specified index if it exists.
    /// - Parameter index: The index of the element to retrieve.
    /// - Returns: The element at the given index, or `nil` if the index is out of bounds.
    func value(at index: Int) -> Element? {
        guard index >= 0 && index < self.count else { return nil }
        return self[index]
    }
}
