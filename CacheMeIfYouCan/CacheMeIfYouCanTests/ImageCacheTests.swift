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
        let expectedChaplinPath = FileSystemPathHelper.path(byAppending: "jerkface.jpg", to: url.path)
        XCTAssertFalse(FileManagerHelper.fileExists(at: expectedChaplinPath))
        
        let cache = ImageCache(rootDirectory: .caches, subdirectoryName: "images")
        
        let chaplinURL = TestImageLoader.TestImage.chaplin.remoteURL
        // Are we starting with nothing in the cache?
        XCTAssertNil(self.fetchFromCache(for: chaplinURL, using: cache))

        guard let remoteChaplin = self.downloadOrCache(for: chaplinURL, using: cache) else {
            XCTFail("Could not get remote Chaplin image!")
            return
        }
        
        // Is the image we downloaded identical?
        let localChaplin = TestImageLoader.localTestImage(named: "jerkface")
        XCTAssertEqual(remoteChaplin.pngData(), localChaplin?.pngData())
        
        // Is the image stored where we think it should be?
        XCTAssertTrue(FileManagerHelper.fileExists(at: expectedChaplinPath))
        
        guard let cachedChaplin = self.fetchFromCache(for: chaplinURL, using: cache) else {
            XCTFail("No Chaplin in the cache!")
            return
        }
        
        // Is the image actually the same everywhere?
        XCTAssertEqual(cachedChaplin.pngData(), remoteChaplin.pngData())
        XCTAssertEqual(cachedChaplin.pngData(), localChaplin?.pngData())
        
        guard let redownloadedOrCachedChaplin = self.downloadOrCache(for: chaplinURL, using: cache) else {
            XCTFail("Couldn't get Chaplin on second call to download or cache!")
            return
        }
        
        XCTAssertEqual(redownloadedOrCachedChaplin.pngData(), cachedChaplin.pngData())
        XCTAssertEqual(redownloadedOrCachedChaplin.pngData(), remoteChaplin.pngData())
        XCTAssertEqual(redownloadedOrCachedChaplin.pngData(), localChaplin?.pngData())
    }
}
