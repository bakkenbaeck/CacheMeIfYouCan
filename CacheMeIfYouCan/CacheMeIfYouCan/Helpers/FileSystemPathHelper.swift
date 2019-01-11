//
//  FilesystemPathHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// A helper struct to make creating paths more readable.
public struct FileSystemPathHelper {
    
    /// Enum wrappers for accessing commonly used directories in the user domain mask.
    public enum UserDirectory: String {
        case caches
        case documents
        
        /// The full path to this directory in the user domain.
        public var path: String {
            let directory: FileManager.SearchPathDirectory
            
            switch self {
            case .caches:
                directory = .cachesDirectory
            case .documents:
                directory = .documentDirectory
            }
            
            guard let path = NSSearchPathForDirectoriesInDomains(directory, .userDomainMask, true).first else {
                fatalError("Could not get \(self.rawValue) directory path!")
            }
            
            return path
        }
        
        /// The URL to this directory
        public var url: URL {
            return URL(fileURLWithPath: self.path)
        }

        /// The full path to the given sub-directory of this directory in the user domain.
        /// - Parameters:
        ///     - subdirectoryName: The name of the sub-direcory you wish to access in the current directory.
        public func pathToSubdirectory(named subdirectoryName: String) -> String {
            return FileSystemPathHelper.path(byAppending: subdirectoryName, to: self.path)
        }
    }
    
    /// Uses the last path component of a URL to create a file name string for the given URL
    ///
    /// - Parameter url: The URL to create a file name for.
    /// - Returns: The last path component as a string
    public static func fileName(from url: URL) -> String {
        return url.lastPathComponent
    }
    
    /// Helper to concatenate paths.
    ///
    /// - Parameters:
    ///   - component: The component to add to the path.
    ///   - existingPath: The existing path
    /// - Returns: The concatenated path
    public static func path(byAppending component: String, to existingPath: String) -> String {
        return (existingPath as NSString).appendingPathComponent(component)
    }
}
