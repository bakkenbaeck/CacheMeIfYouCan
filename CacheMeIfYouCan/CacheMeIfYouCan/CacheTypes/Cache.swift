//
//  Cache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

public protocol Cache: class {
    associatedtype StoredType
    
    /// The queue to perform operations on
    var localQueue: DispatchQueue { get set }
    
    /// Clears everything from the current cache
    func clearAll() throws
    
    /// Performs, on whatever thread its called on, the removal operation.
    ///
    /// - Parameter url: The URL to remove the current item for.
    func removeItem(for url: URL) throws
    
    /// Performs, on whatever thread it's called on, the storage operation
    ///
    /// - Parameters:
    ///   - item: The item to store
    ///   - url: The URL to store it for
    func actuallyStore(item: StoredType, for url: URL) throws
    
    /// Performs, on whatever thread it's called on, the fetch operation.
    ///
    /// - Parameter url: The url to fetch an item for
    /// - Returns: [Optional] The fetched item, or nil
    func actuallyFetchItem(for url: URL) throws -> StoredType?
}

public extension Cache {
    
    /// Stores an item using the local queue
    ///
    /// - Parameters:
    ///   - item: The item to store
    ///   - url: The URL to store it for
    ///   - queue: The queue to fire the completion closure on - defaults to the main queue.
    ///   - completion: [Optional] The completion closure to fire. Defaults to nil.
    public func store(item: StoredType,
                      for url: URL,
                      callbackOn queue: DispatchQueue = .main,
                      completion: (() -> Void)? = nil) { 
        self.localQueue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }

            do {
                try self.actuallyStore(item: item, for: url)
            } catch {
                LogHelper.log("Could not store item: \(error)")
            }
            
            guard let completion = completion else {
                return
            }
            
            queue.async {
                completion()
            }
        }
    }
    
    public func fetchItem(for url: URL,
                          callbackOn queue: DispatchQueue = .main,
                          completion: @escaping (StoredType?) -> Void) {
        self.localQueue.async { [weak self] in
            guard let self = self else {
                completion(nil)
                return
            }
            
            var item: StoredType? = nil
            do {
                item = try self.actuallyFetchItem(for: url)
            } catch {
                LogHelper.log("Could not fetch item: \(error)")
            }
            
            queue.async {
                completion(item)
            }
        }
    }
    
    public func remove(itemFor url: URL,
                       callbackOn queue: DispatchQueue = .main,
                       completion: (() -> Void)? = nil) {
        self.localQueue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            
            do {
                try self.removeItem(for: url)
            } catch {
                LogHelper.log("Could not remove item")
            }
            
            guard let completion = completion else {
                return
            }
            
            queue.async {
                completion()
            }
        }
    }
}
