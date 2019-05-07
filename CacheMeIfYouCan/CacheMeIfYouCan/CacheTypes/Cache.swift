//
//  Cache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// Default caching protocol.
public protocol Cache: class {
    associatedtype StoredType
    
    /// The queue to perform operations on
    var localQueue: DispatchQueue { get set }
    
    /// Clears everything from the current cache
    func clearAll() throws
    
    /// Performs, on whatever thread its called on, the removal operation.
    ///
    /// - Parameter url: The URL to remove the current item for.
    func actuallyRemoveItem(for url: URL) throws
    
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

// MARK: - Default implementation

public extension Cache {
    
    static var defaultQueue: DispatchQueue {
        return DispatchQueue(
            label: String(describing: Self.self),
            qos: .userInitiated,
            attributes: [])
    }
    
    /// Stores an item using the local queue to ensure order of operations
    ///
    /// - Parameters:
    ///   - item: The item to store
    ///   - url: The URL to store it for
    ///   - queue: The queue to fire the completion closure on. Defaults to the main queue.
    ///   - completion: [Optional] The completion closure to fire. Defaults to nil.
    func store(item: StoredType,
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
                try self.actuallyStore(item: item, for: url)
            } catch {
                LogHelper.log("Could not store item: \(error)")
            }
        }
    }
    
    /// Fetches an item using the local queue to ensure order of operations
    ///
    /// - Parameters:
    ///   - url: The URL to search for an item for.
    ///   - queue: The queue to fire the completion closure on. Defaults to the main queue.
    ///   - completion: The completion closure to fire.
    ///                 Params:
    ///                 - [Optional] The stored item found at the given url, or nil.
    func fetchItem(for url: URL,
                          callbackOn queue: DispatchQueue = .main,
                          completion: @escaping (StoredType?) -> Void) {
        self.localQueue.async { [weak self] in
            var item: StoredType? = nil
            defer {
                queue.async {
                    completion(item)
                }
            }
            
            guard let self = self else {
                return
            }
            
            do {
                item = try self.actuallyFetchItem(for: url)
            } catch {
                LogHelper.log("Could not fetch item: \(error)")
            }
        }
    }                                   
    
    /// Fetches an item using the local queue to ensure order of operations
    ///
    /// - Parameters:
    ///   - url: The URL to remove any stored item for.
    ///   - queue: The queue to fire the completion closure on. Defaults to the main queue.
    ///   - completion: [Optional] The completion closure to fire. Defaults to nil.
    func removeItem(for url: URL,
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
                try self.actuallyRemoveItem(for: url)
            } catch {
                LogHelper.log("Could not remove item")
            }
        }
    }
}
