//
//  LogHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// Settings for when to actually log things out
public enum LogSetting {
    /// Will always print logs
    case always
    
    /// Will only debugPrint logs with the prefix of the lib name
    case debugOnly
    
    /// Will never print logs
    case never
    
    /// The current log setting - adjust this var to get your desired behavior throughout the lib.
    public static var current = LogSetting.debugOnly
}

/// A helper class to enable logging with log settings.
public struct LogHelper {
    
    /// The name of the lib, which will be appended when in `debugOnly` mode. 
    public static let libName = "CacheMeIfYouCan"
    
    /// Logging helper method which uses the `LogSetting.current` variable to figure out what to print.
    ///
    /// - Parameters:
    ///   - message: The message to print.
    ///   - file: The file from which this method was called. Defaults to the direct caller.
    ///   - line: The line from which this method was called. Defaults to the direct caller.
    /// - Returns: [Optional] Any string which was logged, or nil if none was logged. Mostly returns this for testing.
    @discardableResult
    public static func log(_ message: @autoclosure () -> String,
                           file: StaticString = #file,
                           line: UInt = #line) -> String? {
        let fullMessage = "\(file) line \(line): \(message())"
        
        switch LogSetting.current {
        case .always:
            print(fullMessage)
            return fullMessage
        case .debugOnly:
            let debugMessage = "\(self.libName): \(fullMessage)"
            debugPrint(debugMessage)
            return debugMessage
        case .never:
            return nil
        }
    }
}
