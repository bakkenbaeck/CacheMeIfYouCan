//
//  LogHelperTests.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import CacheMeIfYouCan
import XCTest

class LogHelperTests: XCTestCase {
    
    override func tearDown() {
        LogSetting.current = .debugOnly
        super.tearDown()
    }
    
    func testAlwaysLogDoesNotHaveDebugPrefix() {
        LogSetting.current = .always
        let logString = "This should return a string with this as the suffix but not the lib name as a prefix"
        guard let returned = LogHelper.log(logString) else {
            XCTFail("No logged string returned")
            return
        }
        
        XCTAssertTrue(returned.hasSuffix(logString))
        XCTAssertFalse(returned.hasPrefix(LogHelper.libName))
    }
    
    func testDebugLogDoesHaveDebugPrefix() {
        LogSetting.current = .debugOnly
        let logString = "This should return a string with this as the suffix and the lib name as a prefix"
        guard let returned = LogHelper.log(logString) else {
            XCTFail("No logged string returned")
            return
        }
        
        XCTAssertTrue(returned.hasSuffix(logString))
        XCTAssertTrue(returned.hasPrefix(LogHelper.libName))
    }
    
    func testNeverLogReturnsNothing() {
        LogSetting.current = .never
        XCTAssertNil(LogHelper.log("This should not return anything"))
    }
}
