//
//  DataConvertibleCodableTests.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 2/21/19.
//  Copyright © 2019 Bakken & Baeck. All rights reserved.
//

import CacheMeIfYouCan
import XCTest

class DataConvertibleCodableTests: XCTestCase {
    
    private let userArray = [
        User(name: "Homer",
             email: "homer@snpp.com",
             isAdmin: false),
        User(name: "Smithers",
             email: "smithers@snpp.com",
             isAdmin: true),
        User(name: "BumblebeeMan",
             email: "bbm@channelocho.tv",
             isAdmin: false)
    ]
    
    private let jsonArray = """
[
    {
        "name": "Homer",
        "email": "homer@snpp.com",
        "isAdmin": false
    },
    {
        "name": "Smithers",
        "email": "smithers@snpp.com",
        "isAdmin": true
    },
    {
        "name": "BumblebeeMan",
        "email": "bbm@channelocho.tv",
        "isAdmin": false
    }
]
"""

    func testEncodingArrayOfUsers() {
        guard let data = self.userArray.toData else {
            XCTFail("No data from array of users")
            return
        }
        
        let noSpacesArray = self.jsonArray
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        let string = String(data: data, encoding: .utf8)
        XCTAssertEqual(string, noSpacesArray)
    }
    
    func testDecodingArrayOfUsers() {
        guard let data = self.jsonArray.data(using: .utf8) else {
            XCTFail("Could not create data from json string")
            return
        }
        
        guard let users = [User].fromData(data) else {
            XCTFail("Could not decode users from data!")
            return
        }
        
        XCTAssertEqual(users, self.userArray)
    }
    
}

