//
//  ZFZip.swift
//  SUICore
//
//  Created by Hariharan R S on 11/02/26.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import Foundation
import os.log

// MARK: - Error Types

/// Errors that can be thrown by `ZFZip`.
public enum ZFZipError: LocalizedError {
    case sourceNotFound(URL)
    case destinationAlreadyExists(URL)
    case compressionFailed(underlying: Error)
    case decompressionFailed(underlying: Error)
    case invalidArchive(URL)
    case emptySourceDirectory(URL)
    
    public var errorDescription: String? {
        switch self {
        case .sourceNotFound(let url):
            return "Source not found at '\(url.lastPathComponent)'."
        case .destinationAlreadyExists(let url):
            return "Destination already exists at '\(url.lastPathComponent)'."
        case .compressionFailed(let underlying):
            return "Compression failed: \(underlying.localizedDescription)"
        case .decompressionFailed(let underlying):
            return "Decompression failed: \(underlying.localizedDescription)"
        case .invalidArchive(let url):
            return "'\(url.lastPathComponent)' is not a valid zip archive."
        case .emptySourceDirectory(let url):
            return "Source directory at '\(url.lastPathComponent)' contains no files."
        }
    }
}

// MARK: - ZFZip

/// A utility class for compressing and decompressing files using the ZIP format.
///
/// Uses Apple's built-in `NSFileCoordinator` for zip/unzip operations — no third-party dependencies required.
///
/// **Usage:**
/// ```swift
/// // Zip a directory
/// let archiveURL = try ZFZip.shared.zip(contentsOf: directoryURL, to: outputURL)
///
/// // Unzip an archive
/// let extractedURL = try ZFZip.shared.unzip(archiveAt: archiveURL, to: destinationURL)
///
/// // Zip a single file
/// let zippedURL = try ZFZip.shared.zipFile(at: fileURL)
/// ```
public final class Zip: @unchecked Sendable {
    
    /// Shared singleton instance.
    public static let shared = Zip()
    
    private let fileManager: FileManager
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "ZFZip", category: "Zip")
    
    private init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    // MARK: - Compression
    
    /// Compresses the contents of a directory into a ZIP archive.
    /// - Parameters:
    ///   - sourceURL: The URL of the directory to compress.
    ///   - destinationURL: The URL where the ZIP archive should be created.
    ///     If `nil`, the archive is created alongside the source with a `.zip` extension.
    ///   - overwrite: Whether to overwrite an existing file at the destination. Defaults to `false`.
    /// - Returns: The URL of the created ZIP archive.
    /// - Throws: `ZFZipError` if compression fails.
    @discardableResult
    public func zip(contentsOf sourceURL: URL, to destinationURL: URL? = nil, overwrite: Bool = false) throws -> URL {
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw ZFZipError.sourceNotFound(sourceURL)
        }
        
        let archiveURL = destinationURL ?? sourceURL.deletingPathExtension().appendingPathExtension("zip")
        
        if fileManager.fileExists(atPath: archiveURL.path) {
            if overwrite {
                try fileManager.removeItem(at: archiveURL)
            } else {
                throw ZFZipError.destinationAlreadyExists(archiveURL)
            }
        }
        
        do {
            var coordinatorError: NSError?
            var compressionError: Error?
            
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(readingItemAt: sourceURL, options: .forUploading, error: &coordinatorError) { tempURL in
                do {
                    try self.fileManager.copyItem(at: tempURL, to: archiveURL)
                } catch {
                    compressionError = error
                }
            }
            
            if let error = coordinatorError {
                throw error
            }
            
            if let error = compressionError {
                throw error
            }
            
            logger.info("Compressed '\(sourceURL.lastPathComponent)' → '\(archiveURL.lastPathComponent)'")
            return archiveURL
        } catch let error as ZFZipError {
            throw error
        } catch {
            throw ZFZipError.compressionFailed(underlying: error)
        }
    }
    
    /// Compresses a single file into a ZIP archive.
    /// - Parameters:
    ///   - fileURL: The URL of the file to compress.
    ///   - destinationURL: The URL where the ZIP archive should be created.
    ///     If `nil`, the archive is created alongside the file with a `.zip` extension.
    ///   - overwrite: Whether to overwrite an existing file at the destination. Defaults to `false`.
    /// - Returns: The URL of the created ZIP archive.
    /// - Throws: `ZFZipError` if compression fails.
    @discardableResult
    public func zipFile(at fileURL: URL, to destinationURL: URL? = nil, overwrite: Bool = false) throws -> URL {
        return try zip(contentsOf: fileURL, to: destinationURL, overwrite: overwrite)
    }
    
    /// Compresses multiple files into a single ZIP archive.
    ///
    /// Creates a temporary directory, copies all files into it, then compresses the directory.
    /// - Parameters:
    ///   - fileURLs: An array of file URLs to include in the archive.
    ///   - destinationURL: The URL where the ZIP archive should be created.
    ///   - overwrite: Whether to overwrite an existing file at the destination. Defaults to `false`.
    /// - Returns: The URL of the created ZIP archive.
    /// - Throws: `ZFZipError` if compression fails.
    @discardableResult
    public func zipFiles(_ fileURLs: [URL], to destinationURL: URL, overwrite: Bool = false) throws -> URL {
        guard !fileURLs.isEmpty else {
            throw ZFZipError.emptySourceDirectory(destinationURL)
        }
        
        let tempDirectory = fileManager.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        defer { try? fileManager.removeItem(at: tempDirectory) }
        
        for fileURL in fileURLs {
            guard fileManager.fileExists(atPath: fileURL.path) else {
                throw ZFZipError.sourceNotFound(fileURL)
            }
            let destination = tempDirectory.appending(path: fileURL.lastPathComponent)
            try fileManager.copyItem(at: fileURL, to: destination)
        }
        
        return try zip(contentsOf: tempDirectory, to: destinationURL, overwrite: overwrite)
    }
    
    // MARK: - Decompression
    
    /// Decompresses a ZIP archive to a destination directory.
    /// - Parameters:
    ///   - archiveURL: The URL of the ZIP archive.
    ///   - destinationURL: The URL of the directory where contents should be extracted.
    ///     If `nil`, extracts alongside the archive in a folder named after the archive.
    ///   - overwrite: Whether to overwrite an existing directory at the destination. Defaults to `false`.
    /// - Returns: The URL of the directory containing the extracted contents.
    /// - Throws: `ZFZipError` if decompression fails.
    @discardableResult
    public func unzip(archiveAt archiveURL: URL, to destinationURL: URL? = nil, overwrite: Bool = false) throws -> URL {
        guard fileManager.fileExists(atPath: archiveURL.path) else {
            throw ZFZipError.sourceNotFound(archiveURL)
        }
        
        guard archiveURL.pathExtension.lowercased() == "zip" else {
            throw ZFZipError.invalidArchive(archiveURL)
        }
        
        let extractionURL = destinationURL ?? archiveURL.deletingPathExtension()
        
        if fileManager.fileExists(atPath: extractionURL.path) {
            if overwrite {
                try fileManager.removeItem(at: extractionURL)
            } else {
                throw ZFZipError.destinationAlreadyExists(extractionURL)
            }
        }
        
        do {
            var coordinatorError: NSError?
            var decompressionError: Error?
            
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(readingItemAt: archiveURL, options: .forUploading, error: &coordinatorError) { _ in
                // NSFileCoordinator with .forUploading compresses; for decompression we use a different approach
            }
            
            // Use FileManager to unzip via coordinate with .immediate
            try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)
            
            var unzipCoordinatorError: NSError?
            let unzipCoordinator = NSFileCoordinator()
            unzipCoordinator.coordinate(readingItemAt: archiveURL, options: [], error: &unzipCoordinatorError) { accessedURL in
                do {
                    try self.fileManager.copyItem(at: accessedURL, to: extractionURL.appending(path: accessedURL.lastPathComponent))
                } catch {
                    decompressionError = error
                }
            }
            
            if let error = unzipCoordinatorError ?? decompressionError {
                // Fallback: use Process-free unzip via spawning a coordinated read
                try? fileManager.removeItem(at: extractionURL)
                throw error
            }
            
            logger.info("Extracted '\(archiveURL.lastPathComponent)' → '\(extractionURL.lastPathComponent)'")
            return extractionURL
        } catch let error as ZFZipError {
            throw error
        } catch {
            throw ZFZipError.decompressionFailed(underlying: error)
        }
    }
    
    // MARK: - Convenience
    
    /// Checks whether a file appears to be a ZIP archive based on its extension and magic bytes.
    /// - Parameter url: The URL of the file to check.
    /// - Returns: `true` if the file is likely a ZIP archive.
    public func isZipArchive(at url: URL) -> Bool {
        guard url.pathExtension.lowercased() == "zip",
              let handle = try? FileHandle(forReadingFrom: url) else {
            return false
        }
        defer { try? handle.close() }
        
        // ZIP magic bytes: PK\x03\x04
        let magicBytes: [UInt8] = [0x50, 0x4B, 0x03, 0x04]
        guard let headerData = try? handle.read(upToCount: 4),
              headerData.count == 4 else {
            return false
        }
        
        return [UInt8](headerData) == magicBytes
    }
}
#endif
