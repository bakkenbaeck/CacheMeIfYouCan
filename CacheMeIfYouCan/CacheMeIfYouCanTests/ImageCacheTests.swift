//
//  ImageCacheTests.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import CacheMeIfYouCan
import XCTest

class ImageCacheTests: XCTestCase {
    
    let homerURL = URL(string: "https://raw.githubusercontent.com/bakkenbaeck/CacheMeIfYouCan/master/CacheMeIfYouCan/CacheMeIfYouCanTests/TestImages/homer.png")!
    
    override func setUp() {
        super.setUp()
        
        let cachesFolder = URL(fileURLWithPath: FilesystemPathHelper.cachesPath)
        try? FileManagerHelper.removeContentsOfFolder(at: cachesFolder)
        
        let documentsFolder = URL(fileURLWithPath: FilesystemPathHelper.documentsPath)
        try? FileManagerHelper.removeContentsOfFolder(at: documentsFolder)
    }
    
    private func downloadOrCache(for url: URL,
                                 using cache: ImageCache,
                                 file: StaticString = #file,
                                 line: UInt = #line) -> UIImage? {
        
        let expectation = self.expectation(description: "Downloaded or cached image")
        
        var image: UIImage? = nil

        cache.fetchOrDownloadItem(
            for: url,
            failureCompletion: { error in
                XCTAssertTrue(Thread.isMainThread,
                              "Should call back on main thread by default!",
                              file: file,
                              line: line)
                XCTFail("Could not fetch or download item. Error: \(String(describing: error))",
                    file: file,
                    line: line)
                expectation.fulfill()
            },
            successCompletion: { fetchedImage in
                XCTAssertTrue(Thread.isMainThread,
                              "Should call back on main thread by default!",
                              file: file,
                              line: line)
                image = fetchedImage
                expectation.fulfill()
            })

        self.wait(for: [expectation], timeout: 10)
        
        return image
    }
    
    private func fetchFromCache(for url: URL,
                                using cache: ImageCache,
                                file: StaticString = #file,
                                line: UInt = #line) -> UIImage? {
        let expectation = self.expectation(description: "Fetched from cache")
        
        var image: UIImage? = nil
        cache.fetchItem(for: url) { fetchedImage in
            XCTAssertTrue(Thread.isMainThread,
                          "Should call back on main thread by default!",
                          file: file,
                          line: line)
            image = fetchedImage
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
        
        return image
    }
    
    private func localTestImage(named imageName: String,
                                file: StaticString = #file,
                                line: UInt = #line) -> UIImage? {
        guard
            let localPath = Bundle(for: ImageCacheTests.self).path(forResource: imageName, ofType: "png", inDirectory: "TestImages"),
            let localData = try? Data(contentsOf: URL(fileURLWithPath: localPath)),
            let localImage = UIImage(data: localData) else {
                XCTFail("Could not get local \(imageName) image!",
                        file: file,
                        line: line)
                return nil
        }
        
        return localImage
    }
    
    func testDownloadOrCache() {
        let cachesImagesPath = FilesystemPathHelper.pathInCachesToFolder(named: "images")
        let url = URL(fileURLWithPath: cachesImagesPath)
        
        // Are we starting without the file downloaded?
        let expectedHomerPath = FilesystemPathHelper.path(byAppending: "homer.png", to: url.path)
        XCTAssertFalse(FileManagerHelper.fileExists(at: expectedHomerPath))
        
        let cache = ImageCache(folderURL: url)
        
        // Are we starting with nothing in the cache?
        XCTAssertNil(self.fetchFromCache(for: self.homerURL, using: cache))

        guard let remoteHomer = self.downloadOrCache(for: self.homerURL, using: cache) else {
            XCTFail("Could not get remote Homer image!")
            return
        }
        
        // Is the image we downloaded identical?
        let localHomer = self.localTestImage(named: "homer")
        XCTAssertEqual(remoteHomer.pngData(), localHomer?.pngData())
        
        // Is the image stored where we think it should be?
        XCTAssertTrue(FileManagerHelper.fileExists(at: expectedHomerPath))
        
        guard let cachedHomer = self.fetchFromCache(for: self.homerURL, using: cache) else {
            XCTFail("You are now a member of the No Homers Club.")
            return
        }
        
        // Is the image actually the same everywhere?
        XCTAssertEqual(cachedHomer.pngData(), remoteHomer.pngData())
        XCTAssertEqual(cachedHomer.pngData(), localHomer?.pngData())
    }
}
