//
//  DownloadHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

/// A Lightweight wrapper to allow downloading of raw `Data`.
open class DownloadHelper {
    
    /// Errors which can occur during download.
    public enum DownloadError: Error {
        /// The response type was not an HTTPResponse
        case invalidResponseType
        
        /// The response code was not somewhere in the 200's range
        /// Param: The response code which was received
        case invalidResponseCode(Int)
        
        /// A valid HTTP Response was received, but there was nil data associated with it.
        case noDataReturned
        
        /// A valid HTTP Response was received, but there was empty data associated with it.
        case emptyDataReturned
    }
    
    /// Loads raw data from a given URL.
    ///
    /// - Parameters:
    ///   - url: The URL to load data from.
    ///   - headers: The headers to use when loading the data.
    ///   - callbackQueue: The queue to call back on when the data is loaded.
    ///   - failureCompletion: The completion closure to execute on error.
    ///                        Param: The error received.
    ///   - successCompletion: The completion closure to execute on success.
    ///                        Param: The data received.
    /// - Returns: A `CancelableTask`, normally a `URLSessionTask`, to allow a download to be cancelled if necessary.
    @discardableResult
    open class func loadData(from url: URL,
                             headers: [String: String],
                             callbackQueue: DispatchQueue,
                             failureCompletion: @escaping (Error) -> Void,
                             successCompletion: @escaping (Data) -> Void) -> CancelableTask? {
        
        var request = URLRequest(url: url)
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                callbackQueue.async {
                    failureCompletion(error)
                }
                return
            }
            
            guard let urlResponse = response as? HTTPURLResponse else {
                callbackQueue.async {
                    failureCompletion(DownloadError.invalidResponseType)
                }
                return
            }
            
            switch urlResponse.statusCode {
            case 200..<300:
                // Legit!
                break
            default:
                callbackQueue.async {
                    failureCompletion(DownloadError.invalidResponseCode(urlResponse.statusCode))
                }
                return
            }
            
            guard let data = data else {
                callbackQueue.async {
                    failureCompletion(DownloadError.noDataReturned)
                }
                return
            }
            
            guard !data.isEmpty else {
                callbackQueue.async {
                    failureCompletion(DownloadError.emptyDataReturned)
                }
                return
            }
            
            // We've got data and it's not empty!
            callbackQueue.async {
                successCompletion(data)
            }
        }
        
        task.resume()
        
        return task
    }
}
