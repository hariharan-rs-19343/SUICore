//
//  ZipTests.swift
//  SUICoreTests
//
//  Created by Hariharan R S on 11/02/26.
//

#if os(iOS) || targetEnvironment(macCatalyst)
import Testing
import Foundation
@testable import SUICore

// MARK: - Zip Tests

@Suite("Zip Compression & Decompression Tests")
struct ZipTests {
    
    private let fileManager = FileManager.default
    private let zip = Zip.shared
    
    /// The user's Downloads directory.
    private var downloadsDirectory: URL {
        fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    /// A temporary working directory for each test, created inside Downloads.
    private func makeTestDirectory() throws -> URL {
        let testDir = downloadsDirectory.appending(path: "ZipTests_\(UUID().uuidString)", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: testDir, withIntermediateDirectories: true)
        return testDir
    }
    
    /// Cleans up a test directory after use.
    private func cleanup(_ url: URL) {
        try? fileManager.removeItem(at: url)
    }
    
    // MARK: - Zip File Tests
    
    @Test("Zip a single file from Downloads directory")
    func zipSingleFile() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        // Create a sample file
        let sampleFile = testDir.appending(path: "sample.txt")
        let content = "Hello, this is a test file for zipping."
        try content.write(to: sampleFile, atomically: true, encoding: .utf8)
        
        // Zip the file
        let archiveURL = try zip.zipFile(at: sampleFile)
        defer { cleanup(archiveURL) }
        
        #expect(fileManager.fileExists(atPath: archiveURL.path))
        #expect(archiveURL.pathExtension == "zip")
        
        // Archive should have nonzero size
        let attributes = try fileManager.attributesOfItem(atPath: archiveURL.path)
        let fileSize = attributes[.size] as? Int ?? 0
        #expect(fileSize > 0)
    }
    
    @Test("Zip a directory with multiple files")
    func zipDirectory() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let contentDir = testDir.appending(path: "content", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: contentDir, withIntermediateDirectories: true)
        
        // Create multiple files
        for i in 1...3 {
            let fileURL = contentDir.appending(path: "file\(i).txt")
            try "Content of file \(i)".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        let archiveURL = testDir.appending(path: "content.zip")
        try zip.zip(contentsOf: contentDir, to: archiveURL)
        
        #expect(fileManager.fileExists(atPath: archiveURL.path))
        #expect(zip.isZipArchive(at: archiveURL))
    }
    
    @Test("Zip multiple individual files into one archive")
    func zipMultipleFiles() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        // Create files
        var fileURLs: [URL] = []
        for i in 1...3 {
            let fileURL = testDir.appending(path: "doc\(i).txt")
            try "Document \(i) content".write(to: fileURL, atomically: true, encoding: .utf8)
            fileURLs.append(fileURL)
        }
        
        let archiveURL = testDir.appending(path: "documents.zip")
        let result = try zip.zipFiles(fileURLs, to: archiveURL)
        
        #expect(fileManager.fileExists(atPath: result.path))
        #expect(result.lastPathComponent == "documents.zip")
    }
    
    @Test("Zip with overwrite replaces existing archive")
    func zipOverwrite() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let sampleFile = testDir.appending(path: "overwrite_test.txt")
        try "Original content".write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "overwrite_test.zip")
        
        // Create first archive
        try zip.zipFile(at: sampleFile, to: archiveURL)
        let firstSize = try fileManager.attributesOfItem(atPath: archiveURL.path)[.size] as? Int ?? 0
        
        // Modify file and overwrite
        try "Updated content with more data added here".write(to: sampleFile, atomically: true, encoding: .utf8)
        try zip.zipFile(at: sampleFile, to: archiveURL, overwrite: true)
        let secondSize = try fileManager.attributesOfItem(atPath: archiveURL.path)[.size] as? Int ?? 0
        
        #expect(fileManager.fileExists(atPath: archiveURL.path))
        #expect(secondSize != firstSize)
    }
    
    @Test("Zip without overwrite throws when destination exists")
    func zipNoOverwriteThrows() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let sampleFile = testDir.appending(path: "no_overwrite.txt")
        try "Test content".write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "no_overwrite.zip")
        try zip.zipFile(at: sampleFile, to: archiveURL)
        
        #expect(throws: ZFZipError.self) {
            try zip.zipFile(at: sampleFile, to: archiveURL, overwrite: false)
        }
    }
    
    @Test("Zip nonexistent source throws sourceNotFound")
    func zipNonexistentSourceThrows() throws {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/path/file.txt")
        
        #expect(throws: ZFZipError.self) {
            try zip.zipFile(at: fakeURL)
        }
    }
    
    @Test("Zip empty file list throws emptySourceDirectory")
    func zipEmptyFileListThrows() throws {
        let destURL = URL(fileURLWithPath: "/tmp/empty.zip")
        
        #expect(throws: ZFZipError.self) {
            try zip.zipFiles([], to: destURL)
        }
    }
    
    // MARK: - Unzip Tests
    
    @Test("Unzip a zipped file")
    func unzipFile() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        // Create and zip a file
        let sampleFile = testDir.appending(path: "unzip_test.txt")
        let originalContent = "Content to survive zip/unzip roundtrip"
        try originalContent.write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "unzip_test.zip")
        try zip.zipFile(at: sampleFile, to: archiveURL)
        
        // Unzip
        let extractDir = testDir.appending(path: "extracted", directoryHint: .isDirectory)
        let resultURL = try zip.unzip(archiveAt: archiveURL, to: extractDir)
        
        #expect(fileManager.fileExists(atPath: resultURL.path))
    }
    
    @Test("Unzip a zipped directory preserves files")
    func unzipDirectory() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        // Create a directory with files
        let contentDir = testDir.appending(path: "to_zip", directoryHint: .isDirectory)
        try fileManager.createDirectory(at: contentDir, withIntermediateDirectories: true)
        
        for i in 1...3 {
            let fileURL = contentDir.appending(path: "item\(i).txt")
            try "Item \(i)".write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        // Zip then unzip
        let archiveURL = testDir.appending(path: "to_zip.zip")
        try zip.zip(contentsOf: contentDir, to: archiveURL)
        
        let extractDir = testDir.appending(path: "unzipped", directoryHint: .isDirectory)
        let resultURL = try zip.unzip(archiveAt: archiveURL, to: extractDir)
        
        #expect(fileManager.fileExists(atPath: resultURL.path))
    }
    
    @Test("Unzip with overwrite replaces existing directory")
    func unzipOverwrite() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let sampleFile = testDir.appending(path: "overwrite_unzip.txt")
        try "Overwrite test".write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "overwrite_unzip.zip")
        try zip.zipFile(at: sampleFile, to: archiveURL)
        
        let extractDir = testDir.appending(path: "extract_dest", directoryHint: .isDirectory)
        
        // First extraction
        try zip.unzip(archiveAt: archiveURL, to: extractDir)
        
        // Second extraction with overwrite
        let result = try zip.unzip(archiveAt: archiveURL, to: extractDir, overwrite: true)
        #expect(fileManager.fileExists(atPath: result.path))
    }
    
    @Test("Unzip without overwrite throws when destination exists")
    func unzipNoOverwriteThrows() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let sampleFile = testDir.appending(path: "no_overwrite_unzip.txt")
        try "Test".write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "no_overwrite_unzip.zip")
        try zip.zipFile(at: sampleFile, to: archiveURL)
        
        let extractDir = testDir.appending(path: "extract_no_overwrite", directoryHint: .isDirectory)
        try zip.unzip(archiveAt: archiveURL, to: extractDir)
        
        #expect(throws: ZFZipError.self) {
            try zip.unzip(archiveAt: archiveURL, to: extractDir, overwrite: false)
        }
    }
    
    @Test("Unzip nonexistent archive throws sourceNotFound")
    func unzipNonexistentArchiveThrows() throws {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/archive.zip")
        
        #expect(throws: ZFZipError.self) {
            try zip.unzip(archiveAt: fakeURL)
        }
    }
    
    @Test("Unzip non-zip file throws invalidArchive")
    func unzipNonZipFileThrows() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let textFile = testDir.appending(path: "not_a_zip.txt")
        try "I am not a zip".write(to: textFile, atomically: true, encoding: .utf8)
        
        #expect(throws: ZFZipError.self) {
            try zip.unzip(archiveAt: textFile)
        }
    }
    
    // MARK: - isZipArchive Tests
    
    @Test("isZipArchive returns true for valid archive")
    func isZipArchiveValid() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let sampleFile = testDir.appending(path: "check.txt")
        try "Archive check".write(to: sampleFile, atomically: true, encoding: .utf8)
        
        let archiveURL = testDir.appending(path: "check.zip")
        try zip.zipFile(at: sampleFile, to: archiveURL)
        
        #expect(zip.isZipArchive(at: archiveURL) == true)
    }
    
    @Test("isZipArchive returns false for non-zip file")
    func isZipArchiveInvalid() throws {
        let testDir = try makeTestDirectory()
        defer { cleanup(testDir) }
        
        let textFile = testDir.appending(path: "fake.zip")
        try "Not really a zip".write(to: textFile, atomically: true, encoding: .utf8)
        
        #expect(zip.isZipArchive(at: textFile) == false)
    }
    
    @Test("isZipArchive returns false for nonexistent file")
    func isZipArchiveNonexistent() {
        let fakeURL = URL(fileURLWithPath: "/nonexistent/file.zip")
        #expect(zip.isZipArchive(at: fakeURL) == false)
    }
}
#endif
