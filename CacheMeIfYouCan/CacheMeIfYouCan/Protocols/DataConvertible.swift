//
//  DataConvertible.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// Errors which can take place with the Data Convertible protocol.
public enum DataConvertibleError: Error {
    /// We were not able to convert the data to the expected type.
    case didNotConvertDataToExpectedType
}

/// A protocol to allow simple generic conversion to and from raw `Data` objects.
public protocol DataConvertible {
    
    /// Attemtps to turn the conforming type to `Data`. Returns `nil` on failure
    var toData: Data? { get }
    
    /// Failable initializer. Fails if data cannot be turned in to the conforming type.
    ///
    /// - Parameter data: The data to attempt to turn into the conforming type.
    init?(data: Data)
}

public extension Array where Element: DataConvertible {
    
    var toData: Data? {
        let datas = self.compactMap { $0.toData }
        if datas.isEmpty {
            return nil
        }
        
        do {
            return try Data.mashTogether(array: datas)
        } catch {
            debugPrint("CacheMeIfYouCan: Error mashing data together: \(error)")
            return nil
        }
    }
    
    static func fromData(_ data: Data) -> [Element]? {
        let datas: [Data]
            
        do {
            datas = try data.unmash()
        } catch {
            debugPrint("CacheMeIfYouCan: Error unmashing data: \(error)")
            return nil
        }
        
        if datas.isEmpty {
            return nil
        }
        
        return datas.compactMap { Element(data: $0) }
    }
}

extension Data {
    
    static func mashTogether(array: [Data]) throws -> Data {
        let base64EncodedStrings = array.map { $0.base64EncodedString() }
        let encoder = JSONEncoder()
        
        return try encoder.encode(base64EncodedStrings)
    }
    
    func unmash() throws -> [Data] {
        let decoder = JSONDecoder()
        let base64Strings = try decoder.decode([String].self, from: self)
        let decodedData = base64Strings.compactMap { Data(base64Encoded: $0) }
        return decodedData
    }
}
