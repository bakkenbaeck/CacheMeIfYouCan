//
//  FilesystemDataCache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// Stores any type which can be converted to raw `Data` on the
/// device's local filesystem.
open class FileSystemDataCache<ConvertibleStoredType: DataConvertible>: Cache {
    
    public typealias StoredType = ConvertibleStoredType
    
    let directoryURL: URL
    
    public lazy var localQueue = FileSystemDataCache.defaultQueue
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - rootDirectory: The root directory where the sub-directory containing this cache should be created.
    ///   - subdirectoryName: [Optional] A non-empty name for the sub-directory of the root to store items in for this cache.
    ///                       If an empty or nil string is passed, the name of the class will be used to create the subdirectory.
    public init(rootDirectory: FileSystemPathHelper.UserDirectory,
                subdirectoryName: String? = nil) {
        let finalSubdirectoryName: String
        if
            let name = subdirectoryName,
            !name.isEmpty {
                finalSubdirectoryName = name
        } else {
            finalSubdirectoryName = String(describing: type(of: self))
        }

        LogHelper.log("Final subdirectory name: \(finalSubdirectoryName)")
        let path = rootDirectory.pathToSubdirectory(named: finalSubdirectoryName)
        
        self.directoryURL = URL(fileURLWithPath: path)
        
        do {
            try FileManagerHelper.createDirectoryIfNeeded(at: self.directoryURL)
        } catch {
            LogHelper.log("Error creating directory: \(error)")
        }
    }
    
    private func localURL(for url: URL) -> URL {
        let fileName = FileSystemPathHelper.fileName(from: url)
        return self.directoryURL
            .appendingPathComponent(fileName)
    }
    
    open func actuallyStore(item: ConvertibleStoredType, for url: URL) throws {
        guard let data = item.toData else {
            return
        }
        
        let url = self.localURL(for: url)
        try data.write(to: url)
    }
    
    open func actuallyStore(items: [ConvertibleStoredType], for url: URL) throws {
        guard let data = items.toData else {
            return
        }
        
        let url = self.localURL(for: url)
        try data.write(to: url)
    }
    
    open func actuallyFetchItem(for url: URL) throws -> ConvertibleStoredType? {
        let url = self.localURL(for: url)
        guard FileManagerHelper.fileExists(at: url) else {
            return nil
        }
    
        let data = try Data(contentsOf: url)
        let item = ConvertibleStoredType(data: data)

        return item
    }
    
    open func actuallyFetchItems(for url: URL) throws -> [ConvertibleStoredType]? {
        let url = self.localURL(for: url)
        
        let data = try Data(contentsOf: url)
        let items = [ConvertibleStoredType].fromData(data)
        
        return items
    }
    
    open func clearAll() throws {
        try FileManagerHelper.removeContentsOfDirectory(at: self.directoryURL)
    }

    open func actuallyRemoveItem(for url: URL) throws {
        let localURL = self.localURL(for: url)
        try FileManagerHelper.removeFile(at: localURL)
    }
    
    // MARK: - Array Storage/Fetching
    
    open func store(items: [ConvertibleStoredType],
                    for url: URL,
                    callbackOn queue: DispatchQueue = .main,
                    completion: (() -> Void)? = nil) {
        self.localQueue.async { [weak self] in
            defer {
                queue.async {
                    completion?()
                }
            }
            
            guard let self = self else {
                return
            }
            
            do {
                try self.actuallyStore(items: items, for: url)
            } catch {
                LogHelper.log("Could not store item: \(error)")
            }
        }
    }
    
    open func fetchItems(for url: URL,
                         callbackOn queue: DispatchQueue = .main,
                         completion: @escaping ([StoredType]?) -> Void) {
        self.localQueue.async { [weak self] in
            var items: [StoredType]? = nil
            defer {
                queue.async {
                    completion(items)
                }
            }
            
            guard let self = self else {
                return
            }
            
            do {
                items = try self.actuallyFetchItems(for: url)
            } catch {
                LogHelper.log("Could not fetch item: \(error)")
            }
        }
    }
    
    // MARK: -  Downloads
    
    /// Gets an array of items from the cache, or if it's not present in the cache, tries to download it from the given URL
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
    ///                           - The array of retrieved items
    ///                           - The URL for which the array was retrieved, in case something's been recycled.
    public func fetchOrDownloadItems(for url: URL,
                                     downloadHeaders: [String: String] = [:],
                                     callbackOn queue: DispatchQueue = .main,
                                     failureCompletion: @escaping (Error) -> Void,
                                     successCompletion: @escaping ([StoredType], URL) -> Void) {
        self.fetchItems(for: url, callbackOn: self.localQueue) { items in
            if let items = items {
                queue.async {
                    successCompletion(items, url)
                }
                
                return
            }
            
            // Else, needs to be downloaded.
            DownloadHelper.loadData(
                from: url,
                headers: downloadHeaders,
                callbackQueue: queue,
                failureCompletion: { error in
                    failureCompletion(error)
                },
                successCompletion: { [weak self] data in
                    guard let downloadedItems = [ConvertibleStoredType].fromData(data) else {
                        failureCompletion(DataConvertibleError.didNotConvertDataToExpectedType)
                        return
                    }
                    
                    guard let self = self else {
                        // Just give back the array, don't try to store it.
                        successCompletion(downloadedItems, url)
                        return
                    }
                    
                    // Store it before giving it back
                    self.store(items: downloadedItems, for: url, callbackOn: queue) {
                        successCompletion(downloadedItems, url)
                    }
                 })
        }
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
                callbackQueue: queue,
                failureCompletion: { error in
                    failureCompletion(error)
                },
                successCompletion: { [weak self] data in
                    guard let item = ConvertibleStoredType(data: data) else {
                        failureCompletion(DataConvertibleError.didNotConvertDataToExpectedType)
                        return
                    }
                    
                    guard let self = self else {
                        // Just give back the item, don't try to store it.
                        successCompletion(item, url)
                        return
                    }
                    
                    // Store it before giving it back
                    self.store(item: item, for: url, callbackOn: queue) {
                        successCompletion(item, url)
                    }
                })
        }
    }
}
