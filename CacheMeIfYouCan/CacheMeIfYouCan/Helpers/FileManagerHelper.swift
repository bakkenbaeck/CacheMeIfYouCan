//
//  FileManagerHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

public struct FileManagerHelper {
    
    public static let fileManager = FileManager.default
    
    public static func fileExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }
    
    public static func fileExists(at url: URL) -> Bool {
        return self.fileExists(at: url.path)
    }
    
    public static func directoryExists(at path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = self.fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
    
    public static func directoryExists(at url: URL) -> Bool {
        return self.directoryExists(at: url.path)
    }
    
    public static func createDirectory(at url: URL) throws {
        try self.fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
    
    public static func createDirectoryIfNeeded(at url: URL) throws {
        if self.directoryExists(at: url) {
            return
        }
        
        try self.createDirectory(at: url)
    }
    
    public static func contentsOfDirectory(at url: URL) throws -> [URL] {
        guard self.directoryExists(at: url) else {
            return []
        }
        
        return try self.fileManager.contentsOfDirectory(at: url,
                                                        includingPropertiesForKeys: nil,
                                                        options: [.skipsHiddenFiles])
    }
    
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
