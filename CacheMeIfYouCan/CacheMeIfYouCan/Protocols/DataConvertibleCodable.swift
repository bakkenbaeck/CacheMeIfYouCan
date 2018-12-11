//
//  DataConvertibleCodable.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

public protocol DataConvertibleCodable: DataConvertible, Codable {
    
    static var encoder: JSONEncoder { get }
    static var decoder: JSONDecoder { get }
}

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
