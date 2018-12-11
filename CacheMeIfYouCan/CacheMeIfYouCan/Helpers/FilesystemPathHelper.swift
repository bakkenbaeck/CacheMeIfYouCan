//
//  FilesystemPathHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

public struct FilesystemPathHelper {
    
    public static func fileName(from url: URL) -> String {
        return url.lastPathComponent
    }
    
    public static var documentsPath: String {
        guard let docsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("Could not get documents directory path!")
        }
        
        return docsPath
    }
    
    public static var cachesPath: String {
        guard let cachesPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first else {
            fatalError("Could not get caches directory path!")
        }
        
        return cachesPath
    }
    
    public static func path(byAppending component: String, to existingPath: String) -> String {
        return (existingPath as NSString).appendingPathComponent(component)
    }
    
    public static func pathInCachesToFolder(named folderName: String) -> String {
        return self.path(byAppending: folderName, to: self.cachesPath)
    }
    
    public static func pathInDocumentsToFolder(named folderName: String) -> String {
        return self.path(byAppending: folderName, to: self.documentsPath)
    }
}