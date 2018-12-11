//
//  FilesystemDataCache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

open class FileSystemDataCache<T: DataConvertible>: Cache {
    
    public typealias StoredType = T
    
    let folderURL: URL
    
    public lazy var localQueue = DispatchQueue(
        label: String(describing: self),
        qos: .userInitiated,
        attributes: [])
    
    public init(folderURL: URL) {
        self.folderURL = folderURL
        
        do {
            try FileManagerHelper.createFolderIfNeeded(at: folderURL)
        } catch {
            LogHelper.log("Error creating folder: \(error)")
        }
    }
    
    private func localURL(for url: URL) -> URL {
        let fileName = FilesystemPathHelper.fileName(from: url)
        return self.folderURL
            .appendingPathComponent(fileName)
    }
    
    open func actuallyStore(item: T, for url: URL) throws {
        guard let data = item.toData else {
            return
        }
        
        let url = self.localURL(for: url)
        try data.write(to: url)
    }
    
    open func actuallyFetchItem(for url: URL) throws -> T? {
        let url = self.localURL(for: url)
    
        let data = try Data(contentsOf: url)
        let item = T.from(data: data)

        return item
    }
    
    open func clearAll() throws {
        try FileManagerHelper.removeContentsOfFolder(at: self.folderURL)
    }

    open func removeItem(for url: URL) throws {
        let localURL = self.localURL(for: url)
        try FileManagerHelper.removeFile(at: localURL)
    }
}
