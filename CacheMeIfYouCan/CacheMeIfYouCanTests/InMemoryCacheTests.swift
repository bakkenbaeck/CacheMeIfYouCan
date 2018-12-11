//
//  InMemoryCacheTests.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import CacheMeIfYouCan
import XCTest

class InMemoryCacheTests: XCTestCase {
    
    private func storeImage(_ image: UIImage,
                            for url: URL,
                            in cache: InMemoryImageCache,
                            file: StaticString = #file,
                            line: UInt = #line) {
        let expectation = self.expectation(description: "Image stored")
        
        cache.store(item: image, for: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callbacks should come back on the main thread by default!",
                          file: file,
                          line: line)
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
    }
    
    private func fetchImage(for url: URL,
                    in cache: InMemoryImageCache,
                    file: StaticString = #file,
                    line: UInt = #line) -> UIImage? {
        
        let expectation = self.expectation(description: "Fetched image")
        
        var image: UIImage? = nil
        
        cache.fetchItem(for: url) { fetchedImage in
            XCTAssertTrue(Thread.isMainThread,
                          "Callbacks should be on the main thread by default!",
                          file: file,
                          line: line)
            image = fetchedImage
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
        
        return image
    }
    
    private func removeImage(for url: URL,
                             in cache: InMemoryImageCache,
                             file: StaticString = #file,
                             line: UInt = #line) {
        let expectation = self.expectation(description: "Removed image")
        
        cache.remove(itemFor: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callbacks should be on the main thread by default!",
                          file: file,
                          line: line)
            expectation.fulfill()
        }
        
        self.wait(for: [expectation], timeout: 1)
    }
    
    func testCachingInMemory() throws {
        guard
            let localHomer = TestImageLoader.localTestImage(.homer),
            let localBurns = TestImageLoader.localTestImage(.burns),
            let localSmithers = TestImageLoader.localTestImage(.smithers) else {
                XCTFail("Could not load local test images!")
                return
        }
        
        let cache = InMemoryImageCache()

        self.storeImage(localHomer, for: TestImageLoader.TestImage.homer.remoteURL, in: cache)
        guard let cachedHomer = self.fetchImage(for: TestImageLoader.TestImage.homer.remoteURL, in: cache) else {
            XCTFail("Couldn't get Homer back")
            return
        }
        
        XCTAssertEqual(cachedHomer.pngData(), localHomer.pngData())
        
        self.storeImage(localBurns, for: TestImageLoader.TestImage.burns.remoteURL, in: cache)
        guard let cachedBurns = self.fetchImage(for: TestImageLoader.TestImage.burns.remoteURL, in: cache) else {
            XCTFail("Couldn't get Mr. Burns back")
            return
        }
        
        XCTAssertEqual(cachedBurns.pngData(), localBurns.pngData())
        
        self.storeImage(localSmithers, for: TestImageLoader.TestImage.smithers.remoteURL, in: cache)
        guard let cachedSmithers = self.fetchImage(for: TestImageLoader.TestImage.smithers.remoteURL, in: cache) else {
            XCTFail("Couldnt get smithers back")
            return
        }
        
        XCTAssertEqual(cachedSmithers.pngData(), localSmithers.pngData())
        
        // Try removing.
        self.removeImage(for: TestImageLoader.TestImage.burns.remoteURL, in: cache)
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.burns.remoteURL, in: cache))

        // Try clearing all
        try cache.clearAll()
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.smithers.remoteURL, in: cache))
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.homer.remoteURL, in: cache))
    }
}
