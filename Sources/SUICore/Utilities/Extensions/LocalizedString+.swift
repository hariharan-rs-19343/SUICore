//
//  LocalizedString+.swift
//  SUICore
//
//  Created by Hariharan R S on 02/09/26.
//

import Foundation

public extension LocalizedStringResource {
    
    public var toString: String {
        return String(localized: self)
    }
}
