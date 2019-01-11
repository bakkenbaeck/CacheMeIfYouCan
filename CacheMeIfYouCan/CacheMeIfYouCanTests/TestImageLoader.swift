//
//  TestImageLoader.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation
import XCTest

class TestImageLoader {
    
    enum TestImage: String {
        case chaplin = "jerkface"
        case georgeMichael = "georgie"
        case bothCats = "both"
        
        var remoteURL: URL {
            switch self {
            case .chaplin:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/jerkface.jpg")!
            case .georgeMichael:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/georgie.jpg")!
            case .bothCats:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/both.jpg")!
            }
        }
    }
    
    static func localTestImage(_ testImage: TestImage,
                               file: StaticString = #file,
                               line: UInt = #line) -> UIImage? {
        return self.localTestImage(named: testImage.rawValue,
                                   file: file,
                                   line: line)
    }
    
    static func localTestImage(named imageName: String,
                               file: StaticString = #file,
                               line: UInt = #line) -> UIImage? {
        guard
            let localPath = Bundle(for: TestImageLoader.self).path(forResource: imageName, ofType: "jpg", inDirectory: "TestImages"),
            let localData = try? Data(contentsOf: URL(fileURLWithPath: localPath)),
            let localImage = UIImage(data: localData) else {
                XCTFail("Could not get local \(imageName) image!",
                    file: file,
                    line: line)
                return nil
        }
        
        return localImage
    }
    
}
