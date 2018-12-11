//
//  DataConvertible.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

public enum DataConvertibleError: Error {
    case didNotConvertDataToExpectedType
}

public protocol DataConvertible {
    
    var toData: Data? { get }
    
    init?(data: Data)
}
