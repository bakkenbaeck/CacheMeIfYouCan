//
//  InMemoryCache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

open class InMemoryCache<ValueType: AnyObject>: Cache {
    public lazy var localQueue = InMemoryCache.defaultQueue
    
    public typealias StoredType = ValueType

    private lazy var underlyingCache: NSCache<NSString, ValueType> = {
        let cache = NSCache<NSString, ValueType>()
        
        return cache
    }()
    
    public init() {
        // Necessary to allow subclasses to initialize
    }
    
    private func key(for url: URL) -> NSString {
        return url.absoluteString as NSString
    }
    
    open func clearAll() throws {
        self.underlyingCache.removeAllObjects()
    }
    
    open func actuallyRemoveItem(for url: URL) throws {
        let key = self.key(for: url)
        self.underlyingCache.removeObject(forKey: key)
    }
    
    open func actuallyStore(item: ValueType, for url: URL) throws {
        let key = self.key(for: url)
        self.underlyingCache.setObject(item, forKey: key)
    }
    
    open func actuallyFetchItem(for url: URL) throws -> ValueType? {
        let key = self.key(for: url)
        return self.underlyingCache.object(forKey: key)
    }
}
