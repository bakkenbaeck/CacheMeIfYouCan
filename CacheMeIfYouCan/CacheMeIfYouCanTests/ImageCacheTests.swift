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
    
    
    override func setUp() {
        super.setUp()
        
        let cachesDirectory = FileSystemPathHelper.UserDirectory.caches.url
        try? FileManagerHelper.removeContentsOfDirectory(at: cachesDirectory)
        
        let documentsDirectory = FileSystemPathHelper.UserDirectory.documents.url
        try? FileManagerHelper.removeContentsOfDirectory(at: documentsDirectory)
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
            successCompletion: { fetchedImage, fetchedURL in
                XCTAssertEqual(fetchedURL,
                               url,
                               "Fetched url was \(fetchedURL) but handed in url was \(url)",
                               file: file,
                               line: line)
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
    
    func testDownloadOrCache() {
        let cachesImagesPath = FileSystemPathHelper.UserDirectory.caches.pathToSubdirectory(named: "images")
        let url = URL(fileURLWithPath: cachesImagesPath)
        
        // Are we starting without the file downloaded?
        let expectedHomerPath = FileSystemPathHelper.path(byAppending: "homer.png", to: url.path)
        XCTAssertFalse(FileManagerHelper.fileExists(at: expectedHomerPath))
        
        let cache = ImageCache(rootDirectory: .caches, subdirectoryName: "images")
        
        let homerURL = TestImageLoader.TestImage.homer.remoteURL
        // Are we starting with nothing in the cache?
        XCTAssertNil(self.fetchFromCache(for: homerURL, using: cache))

        guard let remoteHomer = self.downloadOrCache(for: homerURL, using: cache) else {
            XCTFail("Could not get remote Homer image!")
            return
        }
        
        // Is the image we downloaded identical?
        let localHomer = TestImageLoader.localTestImage(named: "homer")
        XCTAssertEqual(remoteHomer.pngData(), localHomer?.pngData())
        
        // Is the image stored where we think it should be?
        XCTAssertTrue(FileManagerHelper.fileExists(at: expectedHomerPath))
        
        guard let cachedHomer = self.fetchFromCache(for: homerURL, using: cache) else {
            XCTFail("You are now a member of the No Homers Club.")
            return
        }
        
        // Is the image actually the same everywhere?
        XCTAssertEqual(cachedHomer.pngData(), remoteHomer.pngData())
        XCTAssertEqual(cachedHomer.pngData(), localHomer?.pngData())
        
        guard let redownloadedOrCachedHomer = self.downloadOrCache(for: homerURL, using: cache) else {
            XCTFail("Couldn't get homer on second call to download or cache!")
            return
        }
        
        XCTAssertEqual(redownloadedOrCachedHomer.pngData(), cachedHomer.pngData())
        XCTAssertEqual(redownloadedOrCachedHomer.pngData(), remoteHomer.pngData())
        XCTAssertEqual(redownloadedOrCachedHomer.pngData(), localHomer?.pngData())
    }
}
