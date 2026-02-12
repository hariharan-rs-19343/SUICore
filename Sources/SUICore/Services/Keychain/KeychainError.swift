//
//  KeychainError.swift
//  SUICore
//
//  Created by Hariharan R S on 12/02/26.
//

import Foundation

public enum KeychainError: Error, LocalizedError {
    case noPassword                 // No password found for the given key
    case unexpectedPasswordData     // Unexpected data type retrieved from Keychain
    case unableToAccess             // Failed to access Keychain
    case unableToSave               // Failed to save data to Keychain
    case unableToDelete             // Failed to delete data from Keychain
    case notFound                   // No data are found
    
    public var errorDescription: String? {
        switch self {
        case .noPassword:
            return "No password found for the given key."
        case .unexpectedPasswordData:
            return "Unexpected data type retrieved from Keychain."
        case .unableToAccess:
            return "Unable to access Keychain."
        case .unableToSave:
            return "Unable to save data to Keychain."
        case .unableToDelete:
            return "Unable to delete data from Keychain."
        case .notFound:
            return "No data found for the given key."
        }
    }
}
