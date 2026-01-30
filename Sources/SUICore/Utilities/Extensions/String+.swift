//
//  String+.swift
//  ZhareHub
//
//  Created by Hariharan R S on 18/11/24.
//

import Foundation

public extension String {
    /// Converts a string to a `Date` object based on the specified date format.
    ///
    /// - Parameter format: The date format to use for parsing the string (default is "dd-MMM-yyyy HH:mm:ss").
    /// - Returns: A `Date` object if the string can be parsed, otherwise returns the current date.
    func dateFormat(by format: String = "dd-MMM-yyyy HH:mm:ss") -> Date {
        let dateFormatter = DateFormatter()
        
        // Set the date format and time zone.
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        
        // Parse the string to a date object.
        return dateFormatter.date(from: self) ?? Date()
    }

    /// Returns the localized string for the current key.
    ///
    /// This looks for a localized string in the app's Localizable.strings file.
    var ZSLocal: String {
        return NSLocalizedString(self, comment: "")
    }

    /// Marks a string as mandatory by appending a red asterisk to it.
    ///
    /// - Returns: An `AttributedString` where the base string is followed by a red asterisk.
    func mandatory() -> AttributedString {
        // Create an `AttributedString` for the base string.
        var attributedString = AttributedString(self)

        // Create the red asterisk part.
        var asterisk = AttributedString(" *")
        asterisk.foregroundColor = .red
        asterisk.baselineOffset = -2 // Adjusts the positioning of the asterisk to align with the base text.

        // Append the red asterisk to the base attributed string.
        attributedString.append(asterisk)

        return attributedString
    }
}
