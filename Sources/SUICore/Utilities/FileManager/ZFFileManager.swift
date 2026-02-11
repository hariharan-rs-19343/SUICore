//
//  ZFFileManager.swift
//  ZhareHub
//
//  Created by Hariharan R S on 23/12/24.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import Foundation
import UniformTypeIdentifiers
import os.log

// MARK: - Error Types

/// Errors that can be thrown by `ZFFileManager`.
public enum ZFFileManagerError: LocalizedError {
    case bundleIdentifierMissing
    case cacheDirectoryUnavailable
    case fileNotFound(String)
    case cacheSizeRetrievalFailed(underlying: Error)
    case unsupportedFileType
    
    public var errorDescription: String? {
        switch self {
        case .bundleIdentifierMissing:
            return "Bundle Identifier is missing. Unable to locate the cache directory."
        case .cacheDirectoryUnavailable:
            return "Unable to locate the system cache directory."
        case .fileNotFound(let fileName):
            return "File '\(fileName)' not found in the cache directory."
        case .cacheSizeRetrievalFailed(let underlying):
            return "Failed to calculate directory size: \(underlying.localizedDescription)"
        case .unsupportedFileType:
            return "The specified file type has no known file extension."
        }
    }
}

// MARK: - ZFFileManager

public final class ZFFileManager: @unchecked Sendable {
    
    /// Shared singleton instance.
    public static let shared = ZFFileManager()
    
    private let fileManager: FileManager
    private let _appCacheDirectory: URL
    
    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        
        guard let cacheDirectoryURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("System cache directory is unavailable.")
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Bundle Identifier is missing. Unable to locate the cache directory.")
        }
        
        let appCacheURL = cacheDirectoryURL.appending(path: bundleIdentifier, directoryHint: .isDirectory)
        self._appCacheDirectory = appCacheURL
        
        createDirectoryIfNeeded(at: appCacheURL)
    }
    
    // MARK: - Cache Directory Management
    
    /// The URL of the application-specific cache directory.
    /// Creates the directory on first access if it does not exist.
    public var appCacheDirectory: URL {
        return _appCacheDirectory
    }
    
    private func createDirectoryIfNeeded(at directoryURL: URL) {
        guard !fileManager.fileExists(atPath: directoryURL.path) else { return }
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }
    
    // MARK: - File Operations
    
    /// Saves data to the cache directory with the given file name and type.
    /// - Parameters:
    ///   - data: The file data to save.
    ///   - fileName: The name of the file.
    ///   - fileType: The UTType of the file.
    /// - Returns: URL of the saved file.
    /// - Throws: An error if the file cannot be saved.
    public func saveFileToCache(_ data: Data, fileName: String, fileType: UTType) throws -> URL {
        let fileURL = appCacheDirectory.appendingPathComponent(fileName, conformingTo: fileType)
        try data.write(to: fileURL)
        return fileURL
    }
    
    /// Copies a file from a source URL to a destination URL, handling security-scoped resources.
    /// - Parameters:
    ///   - sourceURL: The URL of the source file.
    ///   - destinationURL: The URL where the file should be copied.
    /// - Throws: An error if the copy operation fails.
    public func copyFile(from sourceURL: URL, to destinationURL: URL) throws {
        let needsScopeAccess = sourceURL.startAccessingSecurityScopedResource()
        defer { if needsScopeAccess { sourceURL.stopAccessingSecurityScopedResource() } }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    /// Checks whether a file exists in the cache directory.
    /// - Parameter fileName: The name of the file to check.
    /// - Returns: `true` if the file exists, `false` otherwise.
    public func fileExistsInCacheDirectory(fileName: String) -> Bool {
        let fileURL = appCacheDirectory.appending(path: fileName)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Returns the URL of a cached file if it exists.
    /// - Parameter fileName: The name of the file.
    /// - Returns: The URL of the file in the cache directory.
    /// - Throws: `ZFFileManagerError.fileNotFound` if the file does not exist.
    public func cachedFileURL(for fileName: String) throws -> URL {
        guard fileExistsInCacheDirectory(fileName: fileName) else {
            throw ZFFileManagerError.fileNotFound(fileName)
        }
        return appCacheDirectory.appending(path: fileName)
    }
    
    /// Saves data to the temporary directory.
    /// - Parameters:
    ///   - data: The file data to save.
    ///   - fileType: The UTType of the file.
    ///   - fileName: An optional name; a unique name is generated if `nil`.
    /// - Returns: URL of the saved file.
    /// - Throws: An error if the file cannot be saved.
    public func saveFileToTempDirectory(data: Data, fileType: UTType, fileName: String? = nil) throws -> URL {
        let resolvedName = try fileName ?? generateFileName(with: fileType)
        let fileURL = fileManager.temporaryDirectory.appending(path: resolvedName)
        try data.write(to: fileURL)
        return fileURL
    }
    
    // MARK: - Cleanup
    
    /// Removes all files from the cache directory.
    /// - Throws: An error if the deletion fails.
    public func clearCache() throws {
        let fileURLs = try fileManager.contentsOfDirectory(at: appCacheDirectory, includingPropertiesForKeys: nil)
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Removes a specific file from the cache directory.
    /// - Parameter fileName: The name of the file to delete.
    /// - Throws: An error if the deletion fails.
    public func removeFileFromCache(fileName: String) throws {
        let fileURL = appCacheDirectory.appending(path: fileName)
        try fileManager.removeItem(at: fileURL)
    }
    
    /// Removes all files from the temporary directory without deleting the directory itself.
    /// - Throws: An error if the deletion fails.
    public func clearTemporary() throws {
        let tempDirectory = fileManager.temporaryDirectory
        let fileURLs = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
        for fileURL in fileURLs {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Deletes a file at the given URL if it exists.
    /// - Parameter url: The URL of the file to delete.
    /// - Throws: An error if the deletion fails.
    public func deleteFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }
    
    // MARK: - Utilities
    
    /// Generates a unique file name using the current timestamp and file extension.
    /// - Parameter fileType: The UTType of the file.
    /// - Returns: A unique file name string.
    /// - Throws: `ZFFileManagerError.unsupportedFileType` if the type has no known extension.
    public func generateFileName(with fileType: UTType) throws -> String {
        guard let fileExtension = fileType.preferredFilenameExtension else {
            throw ZFFileManagerError.unsupportedFileType
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyMMdd'@'hh-mm"
        let dateString = dateFormatter.string(from: Date())
        return "\(fileExtension.uppercased())_\(dateString).\(fileExtension)"
    }
    
    /// Calculates the total size of a directory in a human-readable format.
    /// - Parameter directoryURL: The URL of the directory.
    /// - Returns: A formatted string representing the total size.
    /// - Throws: `ZFFileManagerError.cacheSizeRetrievalFailed` if the calculation fails.
    public func getDirectorySize(at directoryURL: URL) throws -> String {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            let totalSize: Int64 = files.reduce(0) { result, fileURL in
                let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return result + Int64(size)
            }
            
            return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
        } catch {
            throw ZFFileManagerError.cacheSizeRetrievalFailed(underlying: error)
        }
    }
}
#endif

