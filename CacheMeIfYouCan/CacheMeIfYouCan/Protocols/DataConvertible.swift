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
        
        return Data.mashTogether(array: datas)
    }
    
    static func fromData(_ data: Data) -> [Element]? {
        let datas = data.unmash
        if datas.isEmpty {
            return nil
        }
        
        return datas.compactMap { Element(data: $0) }
    }
}

extension Data {
    
    private static var separatorData: Data {
        return "====== CACHE ME IF YOU CAN SEPARATOR =====".data(using: .utf8)!
    }
    
    static func mashTogether(array: [Data]) -> Data {
        var data = Data()
        for (index, item) in array.enumerated() {
            data.append(item)
            if index != (array.count - 1) {
                data.append(Data.separatorData)
            }
        }
        
        return data
    }
    
    /// Ganked from: https://stackoverflow.com/a/50476676/681493
    var unmash: [Data] {
        var chunks = [Data]()
        var currentPosition = self.startIndex
        // Find next occurrence of separator after current position:
        while let range = self[currentPosition...].range(of: Data.separatorData) {
            // Append if non-empty:
            if range.lowerBound > currentPosition {
                chunks.append(self[currentPosition..<range.lowerBound])
            }
            // Update current position:
            currentPosition = range.upperBound
        }
        // Append final chunk, if non-empty:
        if currentPosition < self.endIndex {
            chunks.append(self[currentPosition..<endIndex])
        }
        
        return chunks
    }
}
