//
//  FileSystemDataCacheTests.swift
//  CacheMeIfYouCanTests
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import XCTest
import CacheMeIfYouCan

class FileSystemDataCacheTests: XCTestCase {
    
    let user1URL = URL(string: "https://www.url.com/user/1")!
    let user2URL = URL(string: "https://www.url.com/user/2")!
    let user3URL = URL(string: "https://www.url.com/user/3")!
    
    lazy var user1 = User(
        name: "Homer J. Simpson",
        email: "homer@snpp.com",
        isAdmin: false)
    
    lazy var user2 = User(
        name: "C. Montgomery Burns",
        email: "mrburns@snpp.com",
        isAdmin: false)
    
    lazy var user3 = User(
        name: "Waylon Smithers",
        email: "smithers@snpp.com",
        isAdmin: true)
    
    override func setUp() {
        super.setUp()
        
        let cachesFolder = URL(fileURLWithPath: FilesystemPathHelper.cachesPath)
        try? FileManagerHelper.removeContentsOfFolder(at: cachesFolder)
        
        let documentsFolder = URL(fileURLWithPath: FilesystemPathHelper.documentsPath)
        try? FileManagerHelper.removeContentsOfFolder(at: documentsFolder)
    }

    private func storeUser(_ user: User,
                           for url: URL,
                           in cache: UserCache,
                           file: StaticString = #file,
                           line: UInt = #line) {
        let userStoreExpectation = self.expectation(description: "First user store expectation")
        
        cache.store(item: user, for: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on main thread by default",
                          file: file,
                          line: line)
            userStoreExpectation.fulfill()
        }
        
        self.wait(for: [userStoreExpectation], timeout: 1)
    }
    
    private func fetchUser(for url: URL,
                           from cache: UserCache,
                           file: StaticString = #file,
                           line: UInt = #line) -> User? {
        let userRetrieveExpectation = self.expectation(description: "User retrieve expectation")
        
        var retrievedUser: User? = nil
        cache.fetchItem(for: url) { user in
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on main thread by default",
                          file: file,
                          line: line)
            retrievedUser = user
            userRetrieveExpectation.fulfill()
        }
        
        self.wait(for: [userRetrieveExpectation], timeout: 1)
        
        return retrievedUser
    }
    
    private func removeUser(for url: URL,
                            from cache: UserCache,
                            file: StaticString = #file,
                            line: UInt = #line) {
        let userRemoveExpectation = self.expectation(description: "User remove expectation")
        
        cache.remove(itemFor: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on main thread by default",
                          file: file,
                          line: line)
            userRemoveExpectation.fulfill()
        }
        
        self.wait(for: [userRemoveExpectation], timeout: 1)
    }
    
    private func validateStoring(with url: URL) throws {
        XCTAssertFalse(FileManagerHelper.folderExists(at: url))
        XCTAssertEqual(try FileManagerHelper.contentsOfFolder(at: url).count, 0)
        
        let cache = UserCache(folderURL: url)
        
        // Does creating the cache make sure its underlying folder exists?
        XCTAssertTrue(FileManagerHelper.folderExists(at: url))
        XCTAssertEqual(try FileManagerHelper.contentsOfFolder(at: url).count, 0)
        
        // Store some users and make sure they're stored and can be retrieved
        self.storeUser(self.user1, for: self.user1URL, in: cache)
        
        let user1ExpectedPath = FilesystemPathHelper.path(byAppending: "1", to: url.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user1ExpectedPath))
        
        guard let fetchedUser1 = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Could not fetch user 1!")
            return
        }
        
        XCTAssertEqual(fetchedUser1, self.user1)
        
        self.storeUser(user2, for: user2URL, in: cache)
        
        let user2ExpectedPath = FilesystemPathHelper.path(byAppending: "2", to: url.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user2ExpectedPath))
        
        guard let fetchedUser2 = self.fetchUser(for: self.user2URL, from: cache) else {
            XCTFail("Could not fetch user 2!")
            return
        }
        
        XCTAssertEqual(fetchedUser2, self.user2)
        
        self.storeUser(self.user3, for: self.user3URL, in: cache)
        
        let user3ExpectedPath = FilesystemPathHelper.path(byAppending: "3", to: url.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        guard let fetchedUser3 = self.fetchUser(for: self.user3URL, from: cache) else {
            XCTFail("Could not fetch user 3!")
            return
        }
        
        XCTAssertEqual(fetchedUser3, self.user3)
        
        // Remove an item and make sure it's gone 
        self.removeUser(for: self.user3URL, from: cache)
        
        XCTAssertNil(self.fetchUser(for: self.user3URL, from: cache))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        // Get rid of EVERYTHING
        try cache.clearAll()
        
        // The folder should still exist
        XCTAssertTrue(FileManagerHelper.folderExists(at: url))
        
        // But all three users should be removed
        XCTAssertFalse(FileManagerHelper.fileExists(at: user1ExpectedPath))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user2ExpectedPath))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        // As should anything else in there
        XCTAssertEqual(try FileManagerHelper.contentsOfFolder(at: url).count, 0)
    }
    
    private func validateReplacingItem(url: URL) {
        let cache = UserCache(folderURL: url)
        
        self.storeUser(self.user1, for: self.user1URL, in: cache)
        guard let user1 = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Could not fetch user from cache!")
            return
        }
        
        XCTAssertEqual(user1, self.user1)
        
        // Now, store a different user for the same key
        self.storeUser(self.user2, for: self.user1URL, in: cache)
        
        guard let user2 = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Could not fetch user from cache!")
            return
        }
        
        XCTAssertEqual(user2, self.user2)
    }
    
    // MARK: - Tests
    
    func testStoringInCachesDirectory() throws {
        let usersInCaches = FilesystemPathHelper.pathInCachesToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInCaches)
        try self.validateStoring(with: url)
    }
    
    func testStoringInDocumentsDirectory() throws {
        let usersInDocuments = FilesystemPathHelper.pathInDocumentsToFolder(named: "documents")
        let url = URL(fileURLWithPath: usersInDocuments)
        try self.validateStoring(with: url)
    }
    
    func testReplacingExistingStoredItemInCaches() {
        let usersInCaches = FilesystemPathHelper.pathInCachesToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInCaches)
        self.validateReplacingItem(url: url)
    }
    
    func testReplacingExistingStoredItemInDocuments() {
        let usersInDocuments = FilesystemPathHelper.pathInDocumentsToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInDocuments)
        self.validateReplacingItem(url: url)
    }
    
    func testCallingBackOnNonMainQueue() {
        let queue = DispatchQueue(label: "testQueue", qos: .userInitiated, attributes: [.concurrent])
        
        let usersInDocuments = FilesystemPathHelper.pathInDocumentsToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInDocuments)
        let cache = UserCache(folderURL: url)
        
        let storeExpectation = self.expectation(description: "Stored Expectation")
        cache.store(item: self.user1, for: self.user1URL, callbackOn: queue) {
            XCTAssertFalse(Thread.isMainThread)
            storeExpectation.fulfill()
        }
        
        self.wait(for: [storeExpectation], timeout: 1)
        
        let fetchExpectation = self.expectation(description: "Fetched expectation")
        cache.fetchItem(for: self.user1URL, callbackOn: queue) { user in
            defer {
                fetchExpectation.fulfill()
            }
            
            XCTAssertFalse(Thread.isMainThread)
            guard let user = user else {
                XCTFail("Did not fetch user!")
                return
            }
            
            XCTAssertEqual(user, self.user1)
        }
        
        self.wait(for: [fetchExpectation], timeout: 1)
    }
    
    func testCachingWithoutWaitingReturnsCachedItem() {
        let usersInDocuments = FilesystemPathHelper.pathInDocumentsToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInDocuments)
        let cache = UserCache(folderURL: url)
        
        // Store, but don't wait for the completion to fire before trying to grab it again.
        cache.store(item: self.user1, for: self.user1URL)
        
        let fetchedUser = self.fetchUser(for: self.user1URL, from: cache)
        XCTAssertEqual(fetchedUser, self.user1)
    }
    
    func testRemovingWithoutWaitingDoesReturnCachedItem() {
        let usersInDocuments = FilesystemPathHelper.pathInDocumentsToFolder(named: "users")
        let url = URL(fileURLWithPath: usersInDocuments)
        let cache = UserCache(folderURL: url)
        
        self.storeUser(self.user1, for: self.user1URL, in: cache)
        guard let initialFetchedUser = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Initial user was not stored!")
            return
        }
        
        XCTAssertEqual(initialFetchedUser, self.user1)
        
        // Remove, but don't wait for the completion to fire before trying to grab it again.
        cache.remove(itemFor: self.user1URL)
        
        let fetchedUser = self.fetchUser(for: self.user1URL, from: cache)
        XCTAssertNil(fetchedUser)
    }
}
