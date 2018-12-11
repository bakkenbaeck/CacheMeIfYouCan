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
        case burns
        case homer
        case smithers
        
        var remoteURL: URL {
            switch self {
            case .burns:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/burns.png")!
            case .homer:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/homer.png")!
            case .smithers:
                return URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/smithers.png")!
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
            let localPath = Bundle(for: TestImageLoader.self).path(forResource: imageName, ofType: "png", inDirectory: "TestImages"),
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
