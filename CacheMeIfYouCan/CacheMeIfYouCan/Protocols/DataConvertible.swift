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
    
    var toData: Data? { get }
    
    init?(data: Data)
}
