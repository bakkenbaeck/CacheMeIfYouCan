//
//  TestHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/17/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

struct TestHelper {
    
    static var isTesting: Bool {
        // If we can see XCTestCase as a class, we're testing. 
        return NSClassFromString("XCTestCase") != nil
    }
}
