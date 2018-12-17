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
    
    let directoryURL: URL
    
    public lazy var localQueue = FileSystemDataCache.defaultQueue
    
    
    /// Designated initializer.
    ///
    /// - Parameters:
    ///   - rootDirectory: The root directory where the 
    ///   - subdirectoryName: A non-empty name for the sub-directory of the root to store items in for this cache. NOTE: An empty string will cause this initializer to fail.
    public init?(rootDirectory: FileSystemPathHelper.UserDirectory,
                 subdirectoryName: String) {
        guard !subdirectoryName.isEmpty else {
            if !TestHelper.isTesting {
                // Tell the developer they shouldn't be doing this during development.
                assertionFailure("You need to pass in a sub-directory name!")
            }
            return nil
        }
        
        let path = rootDirectory.pathToSubdirectory(named: subdirectoryName)
        
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
        try FileManagerHelper.removeContentsOfDirectory(at: self.directoryURL)
    }

    open func actuallyRemoveItem(for url: URL) throws {
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
