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
    
    /// Gets the item from the cache, or if it's not present in the cache, tries to download it from the given URL
    ///
    /// - Parameters:
    ///   - url: The URL to try and find an item for
    ///   - downloadHeaders: Any download headers to add to the download request (for example, Auth headers).
    ///                      Defaults to an empty dictionary.
    ///   - queue: The queue to call back on. Defaults to the main queue.
    ///   - failureCompletion: The completion closure to execute on failure.
    ///                        Param: - Any error which was encountered trying to download. If an error is encountered
    ///                                 trying to read, download will be tried automatically.
    ///   - successCompletion: The completion closure to execute on success.
    ///                        Params:
    ///                           - The retrieved item
    ///                           - The URL for which it was retrieved, in case something's been recycled.
    public func fetchOrDownloadItem(for url: URL,
                                    downloadHeaders: [String: String] = [:],
                                    callbackOn queue: DispatchQueue = .main,
                                    failureCompletion: @escaping (Error) -> Void,
                                    successCompletion: @escaping (StoredType, URL) -> Void) {
        self.fetchItem(for: url, callbackOn: self.localQueue) { item in
            if let item = item {
                queue.async {
                    successCompletion(item, url)
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
                            failureCompletion(DataConvertibleError.didNotConvertDataToExpectedType)
                        }
                        return
                    }
                    
                    guard let self = self else {
                        // Just give back the item, don't try to store it.
                        queue.async {
                            successCompletion(item, url)
                        }
                        
                        return
                    }
                    
                    // Store it before giving it back
                    self.store(item: item, for: url, callbackOn: self.localQueue) {
                        queue.async {
                            successCompletion(item, url)
                        }
                    }
                })
        }
    }
}
