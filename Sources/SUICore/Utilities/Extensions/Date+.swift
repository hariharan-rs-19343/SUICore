//
//  Date+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 07/01/25.
//

import Foundation

public extension Date {
    /// Calculates the number of days between the current date (`self`) and the given target date.
    /// - Parameter targetDate: The date to which the difference in days is calculated.
    /// - Returns: The number of days between the current date (`self`) and `targetDate`.
    func daysUntilTargetDate(targetDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: self, to: targetDate)
        return components.day ?? 0
    }
    
    static func timeStamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }
}
