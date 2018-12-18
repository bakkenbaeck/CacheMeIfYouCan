//
//  DataConvertibleCodable.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// An extension of the `Codable` protocol to also allow it to be `DataConvertible`.
public protocol DataConvertibleCodable: DataConvertible, Codable {
    
    // The encoder to use for this type.
    static var encoder: JSONEncoder { get }
    
    // The decoder to use for this type.
    static var decoder: JSONDecoder { get }
}

// MARK: - Default implementation

public extension DataConvertibleCodable {
    
    var toData: Data? {
        return try? Self.encoder.encode(self)
    }
    
    init?(data: Data) {
        guard let decoded = try? Self.decoder.decode(Self.self, from: data) else {
            return nil
        }
        
        self = decoded
    }
}
