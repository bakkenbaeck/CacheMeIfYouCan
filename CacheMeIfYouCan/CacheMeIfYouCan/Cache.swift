//
//  Cache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

open class Cache<StoredType> {
    
    open lazy var localQueue = DispatchQueue(
        label: String(describing: self),
        qos: DispatchQoS.userInitiated,
        attributes: [.concurrent])
    
    
    /// Abstract method which should be overridden by sublcasses to perform,
    /// on whatever thread it's called on, the storage operation.
    ///
    /// - Parameters:
    ///   - item: The item to store
    ///   - for: The URL to store the item for
    open func actuallyStore(item: StoredType, for url: URL) throws {
        assertionFailure("Subclasses must override!")
    }
    
    /// Abstract method which should be overridden by subclasses to perform,
    /// on whatever thread it's called on, the fetch operation
    ///
    /// - Parameter url: The URL to fetch a stored item for
    /// - Returns: [Optional] The stored item for the URL, or nil if none is stored.
    open func actuallyFetchItem(for url: URL) throws -> StoredType? {
        assertionFailure("Subclasses must override!")
        return nil
    }
    
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
                return
            }

            do {
                try self.actuallyStore(item: item, for: url)
            } catch {
                // TODO: Logging mechanism
                debugPrint("Could not store item: \(error)")
            }
            
            queue.async {
                completion?()
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
                debugPrint("Could not fetch item: \(error)")
            }
            
            queue.async {
                completion(item)
            }
        }
    }
}
