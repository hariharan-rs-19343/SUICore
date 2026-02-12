//
//  KeychainService.swift
//  SUICore
//
//  Created by Hariharan R S on 12/02/26.
//


import Foundation

/// Service to manage saving, retrieving, and deleting data in Keychain
public struct KeychainService {
    
    // Add a default service identifier
    private static let defaultService = Bundle.main.bundleIdentifier ?? "com.meadmin.app"
    
    /// Accessibility level for keychain items
    public enum AccessibilityLevel {
        case whenUnlocked
        case afterFirstUnlock
        case always
        case whenPasscodeSetThisDeviceOnly
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlockThisDeviceOnly
        case alwaysThisDeviceOnly
        
        var value: CFString {
            switch self {
            case .whenUnlocked: return kSecAttrAccessibleWhenUnlocked
            case .afterFirstUnlock: return kSecAttrAccessibleAfterFirstUnlock
            case .always: return kSecAttrAccessibleAfterFirstUnlock
            case .whenPasscodeSetThisDeviceOnly: return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .whenUnlockedThisDeviceOnly: return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlockThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .alwaysThisDeviceOnly: return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            }
        }
    }
    
    /// Saves a value of any Codable type into the Keychain for a specified key
    /// - Parameters:
    ///   - value: The value to be saved, must conform to Codable
    ///   - key: The key used to identify the stored value
    ///   - service: The service identifier (optional, defaults to the app's bundle ID)
    ///   - accessibility: The accessibility level for the keychain item
    /// - Throws: Throws KeychainError.unableToSave if saving fails
    public static func save<T: Codable>(
        value: T,
        forKey key: String,
        service: String? = nil,
        accessibility: AccessibilityLevel = .afterFirstUnlock
    ) throws {
        let actualService = service ?? defaultService
        debugPrint("Service: \(actualService), Key: \(key)")
        
        // Check if the item already exists - if so, update it
        if (try? retrieve(forKey: key, service: actualService) as T) != nil {
            try update(value: value, forKey: key, service: actualService, accessibility: accessibility)
            return
        }
        
        let data = try JSONEncoder().encode(value)
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: actualService,
            kSecAttrAccount: key,
            kSecValueData: data,
            kSecAttrAccessible: accessibility.value
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }
    
    /// Retrieves a value of any Codable type from the Keychain for a specified key
    /// - Parameters:
    ///   - key: The key used to retrieve the value
    ///   - service: The service identifier (optional, defaults to the app's bundle ID)
    /// - Returns: The decoded value of the specified Codable type
    /// - Throws: Throws specific KeychainError cases if retrieval fails
    public static func retrieve<T: Codable>(forKey key: String, service: String? = nil) throws -> T {
        let actualService = service ?? defaultService
        debugPrint("Service: \(actualService), Key: \(key)")
        
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: actualService,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.notFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unableToAccess
        }
        
        guard let data = item as? Data else {
            throw KeychainError.unexpectedPasswordData
        }
        
        let value = try JSONDecoder().decode(T.self, from: data)
        return value
    }
    
    /// Deletes an item from the Keychain for a specified key
    /// - Parameters:
    ///   - key: The key for the item to be deleted
    ///   - service: The service identifier (optional, defaults to the app's bundle ID)
    /// - Throws: Throws KeychainError.unableToDelete if deletion fails
    public static func delete(forKey key: String, service: String? = nil) throws {
        let actualService = service ?? defaultService
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: actualService,
            kSecAttrAccount: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }
    
    /// Update an existing item in the Keychain
    /// - Parameters:
    ///   - value: The value to update, must conform to Codable
    ///   - key: The key used to identify the stored value
    ///   - service: The service identifier (optional, defaults to the app's bundle ID)
    ///   - accessibility: The accessibility level for the keychain item
    /// - Throws: Throws KeychainError if updating fails
    public static func update<T: Codable>(
        value: T,
        forKey key: String,
        service: String? = nil,
        accessibility: AccessibilityLevel = .afterFirstUnlock
    ) throws {
        let actualService = service ?? defaultService
        let data = try JSONEncoder().encode(value)
        
        // Query to find the existing item
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: actualService,
            kSecAttrAccount: key
        ]
        
        let attributesToUpdate: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: accessibility.value
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            try save(value: value, forKey: key, service: actualService, accessibility: accessibility)
        } else if status != errSecSuccess {
            throw KeychainError.unableToSave
        }
    }
    
    /// Check if an item exists in the keychain
    /// - Parameters:
    ///   - key: The key to check
    ///   - service: The service identifier (optional, defaults to the app's bundle ID)
    /// - Returns: Boolean indicating whether the item exists
    public static func exists(forKey key: String, service: String? = nil) -> Bool {
        let actualService = service ?? defaultService
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: actualService,
            kSecAttrAccount: key,
            kSecReturnData: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
