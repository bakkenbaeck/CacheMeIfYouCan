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
    
    public lazy var localQueue = FileSystemDataCache.defaultQueue
    
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
        guard FileManagerHelper.fileExists(at: url) else {
            return nil
        }
    
        let data = try Data(contentsOf: url)
        let item = T(data: data)

        return item
    }
    
    open func clearAll() throws {
        try FileManagerHelper.removeContentsOfFolder(at: self.folderURL)
    }

    open func removeItem(for url: URL) throws {
        let localURL = self.localURL(for: url)
        try FileManagerHelper.removeFile(at: localURL)
    }
    
    
    public func fetchOrDownloadItem(for url: URL,
                                    downloadHeaders: [String: String] = [:],
                                    callbackOn queue: DispatchQueue = .main,
                                    failureCompletion: @escaping (Error?) -> Void,
                                    successCompletion: @escaping (StoredType) -> Void) {
        self.fetchItem(for: url, callbackOn: self.localQueue) { item in
            if let item = item {
                queue.async {
                    successCompletion(item)
                }
                
                return
            }
            
            // Else, needs to be downloaded.
            DownloadHelper.loadData(
                from: url,
                headers: downloadHeaders,
                failureCompletion: { error in
                    queue.async {
                        failureCompletion(error)
                    }
                },
                successCompletion: { [weak self] data in
                    guard let item = T(data: data) else {
                        queue.async {
                            failureCompletion(nil)
                        }
                        return
                    }
                    
                    guard let self = self else {
                        // Just give back the item, don't try to store it.
                        queue.async {
                            successCompletion(item)
                        }
                        
                        return
                    }
                    
                    // Store it before giving it back
                    self.store(item: item, for: url, callbackOn: self.localQueue) {
                        queue.async {
                            successCompletion(item)
                        }
                    }
                })
        }
    }
}
