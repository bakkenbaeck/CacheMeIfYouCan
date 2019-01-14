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
        
        cache.removeItem(for: url) {
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
            let localChaplin = TestImageLoader.localTestImage(.chaplin),
            let localGeorgie = TestImageLoader.localTestImage(.georgeMichael),
            let localBoth = TestImageLoader.localTestImage(.bothCats) else {
                XCTFail("Could not load local test images!")
                return
        }
        
        let cache = InMemoryImageCache()

        self.storeImage(localChaplin, for: TestImageLoader.TestImage.chaplin.remoteURL, in: cache)
        guard let cachedChaplin = self.fetchImage(for: TestImageLoader.TestImage.chaplin.remoteURL, in: cache) else {
            XCTFail("Couldn't get Chaplin back")
            return
        }
        
        XCTAssertEqual(cachedChaplin.pngData(), localChaplin.pngData())
        
        self.storeImage(localGeorgie, for: TestImageLoader.TestImage.georgeMichael.remoteURL, in: cache)
        guard let cachedGeorgie = self.fetchImage(for: TestImageLoader.TestImage.georgeMichael.remoteURL, in: cache) else {
            XCTFail("Couldn't get George Michael back")
            return
        }
        
        XCTAssertEqual(cachedGeorgie.pngData(), localGeorgie.pngData())
        
        self.storeImage(localBoth, for: TestImageLoader.TestImage.bothCats.remoteURL, in: cache)
        guard let cachedBoth = self.fetchImage(for: TestImageLoader.TestImage.bothCats.remoteURL, in: cache) else {
            XCTFail("Couldnt get both cats back")
            return
        }
        
        XCTAssertEqual(cachedBoth.pngData(), localBoth.pngData())
        
        // Try removing.
        self.removeImage(for: TestImageLoader.TestImage.georgeMichael.remoteURL, in: cache)
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.georgeMichael.remoteURL, in: cache))

        // Try clearing all
        try cache.clearAll()
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.chaplin.remoteURL, in: cache))
        XCTAssertNil(self.fetchImage(for: TestImageLoader.TestImage.bothCats.remoteURL, in: cache))
    }
}
