//
//  UserCache.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation
import CacheMeIfYouCan

struct User: DataConvertibleCodable {
    static var encoder = JSONEncoder()
    
    static var decoder = JSONDecoder()
    
    let name: String
    let email: String
    let isAdmin: Bool
    
    init(name: String,
         email: String,
         isAdmin: Bool) {
        self.name = name
        self.email = email
        self.isAdmin = isAdmin
    }
}

extension User: Equatable {}

class UserCache: FileSystemDataCache<User> {}
