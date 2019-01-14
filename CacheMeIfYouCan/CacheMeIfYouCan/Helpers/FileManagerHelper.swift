//
//  FileManagerHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// Helper struct to try and make some `FileManager` stuff more readable
public struct FileManagerHelper {
    
    public static let fileManager = FileManager.default
    
    /// Checks if a file exists at a given path, and is not a directory.
    ///
    /// NOTE: Apple acknowledges when not being careful with threads, this can be an issue. See note here: https://developer.apple.com/documentation/foundation/filemanager/1410277-fileexists
    ///
    ///
    /// - Parameter path: The path to check
    /// - Returns: True if the path is to a file, false if it is to nothing or to a directory.
    public static func fileExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }
    
    /// Checks if a file exists at a given URL, and is not a directory
    ///
    /// NOTE: Apple acknowledges when not being careful with threads, this can be an issue. See note here: https://developer.apple.com/documentation/foundation/filemanager/1410277-fileexists
    ///
    /// - Parameter url: The file URL to check
    /// - Returns: True if the URL is to a file, false if it is to nothing or to a directory
    public static func fileExists(at url: URL) -> Bool {
        return self.fileExists(at: url.path)
    }
    
    /// Checks if a directory exists at a given path
    ///
    /// NOTE: Apple acknowledges when not being careful with threads, this can be an issue. See note here: https://developer.apple.com/documentation/foundation/filemanager/1410277-fileexists
    ///
    /// - Parameter path: The path to check
    /// - Returns: True if the path is to a directory, false if it is to nothing or to a file.
    public static func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    /// Checks if a directory exists at a given URL
    ///
    /// NOTE: Apple acknowledges when not being careful with threads, this can be an issue. See note here: https://developer.apple.com/documentation/foundation/filemanager/1410277-fileexists
    ///
    /// - Parameter url: The file URL to check
    /// - Returns: True if the URL is to a directory, false if it is to nothing or to a file.
    public static func directoryExists(at url: URL) -> Bool {
        return self.directoryExists(at: url.path)
    }
    
    /// Attempts to create a directory at the given URL.
    ///
    /// - Parameter url: The URL to create a directory at.
    /// - Throws: Any error encountered during creation, including that the directory already exists.
    public static func createDirectory(at url: URL) throws {
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    
    /// Creates a directory at the given URL if it does not already exist
    ///
    /// - Parameter url: The URL to create a directory at.
    /// - Throws: Any error encountered during creation, theoretically not including that the directory already exists.
    public static func createDirectoryIfNeeded(at url: URL) throws {
        if self.directoryExists(at: url) {
            return
        }
        
        try self.createDirectory(at: url)
    }
    
    /// Gets all items in a directory except hidden files.
    ///
    /// - Parameter url: The URL of the directory to get contents of.
    /// - Returns: The contents of that directory excepting hidden files, or an empty array if that directory does not exist.
    /// - Throws: Any error getting the contents of the directory, except that the directory doesn't exist.
    public static func contentsOfDirectory(at url: URL) throws -> [URL] {
        guard self.directoryExists(at: url) else {
            return []
        }
        
        return try self.fileManager.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
    }
    
    /// Removes everything from a directory
    ///
    /// - Parameter url: The URL of the directory to remove everything from
    /// - Throws: Any error encountered attempting to remove any item, theoretically not including that the directory doesn't exist.
    public static func removeContentsOfDirectory(at url: URL) throws {
        guard self.directoryExists(at: url) else {
            // Nothing to remove
            return
        }
        
        let urls = try self.contentsOfDirectory(at: url)
        try urls.forEach { fileURL in
            try self.fileManager.removeItem(at: fileURL)
        }
    }
    
    public static func removeFile(at url: URL) throws {
        guard self.fileExists(at: url) else {
            return
        }
        
        try self.fileManager.removeItem(at: url)
    }
}
