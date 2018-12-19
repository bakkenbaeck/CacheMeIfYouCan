//
//  DownloadHelper.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

extension URLSessionTask: CancelableTask {}

open class DownloadHelper {
    
    public enum DownloadError: Error {
        case invalidResponseType
        case invalidResponseCode(Int)
        case noDataReturned
        case emptyDataReturned
    }
    
    @discardableResult
    open class func loadData(from url: URL,
                             headers: [String: String],
                             failureCompletion: @escaping (Error) -> Void,
                             successCompletion: @escaping (Data) -> Void) -> CancelableTask? {
        
        var request = URLRequest(url: url)
        headers.forEach { request.addValue($0.value, forHTTPHeaderField: $0.key) }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                failureCompletion(error)
                return
            }
            
            guard let urlResponse = response as? HTTPURLResponse else {
                failureCompletion(DownloadError.invalidResponseType)
                return
            }
            
            switch urlResponse.statusCode {
            case 200..<300:
                // Legit!
                break
            default:
                failureCompletion(DownloadError.invalidResponseCode(urlResponse.statusCode))
                return
            }
            
            guard let data = data else {
                failureCompletion(DownloadError.noDataReturned)
                return
            }
            
            guard !data.isEmpty else {
                failureCompletion(DownloadError.emptyDataReturned)
                return
            }
            
            // We've got data and it's not empty!
            successCompletion(data)
        }
        
        task.resume()
        
        return task
    }
}
