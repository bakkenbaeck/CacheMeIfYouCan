//
//  CancelableTask.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

// Wrapper protocol to allow mock URL sessions to pretend to "cancel" tasks.
public protocol CancelableTask {
    func cancel()
}

// Auto-conformance for URLSession
extension URLSessionTask: CancelableTask { /* mix-in */ }
