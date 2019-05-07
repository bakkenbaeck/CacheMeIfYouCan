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
    
    let allUsersURL = URL(string: "https://www.url.com/user/all")!

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
        
        let cachesDirectory = FileSystemPathHelper.UserDirectory.caches.url
        try? FileManagerHelper.removeContentsOfDirectory(at: cachesDirectory)
        
        let documentsDirectory = FileSystemPathHelper.UserDirectory.documents.url
        try? FileManagerHelper.removeContentsOfDirectory(at: documentsDirectory)
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
    
    private func storeUserArray(_ users: [User],
                                for url: URL,
                                in cache: UserCache,
                                file: StaticString = #file,
                                line: UInt = #line) {
        let arrayStoreExpectation = self.expectation(description: "User array store expectation")
        cache.store(items: users, for: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on the main thread by default",
                          file: file,
                          line: line)
            arrayStoreExpectation.fulfill()
        }
        
        self.wait(for: [arrayStoreExpectation], timeout: 1)
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
    
    private func fetchUserArray(for url: URL,
                                from cache: UserCache,
                                file: StaticString = #file,
                                line: UInt = #line) -> [User]? {
        let userArrayRetrieveExpectation = self.expectation(description: "User array retrieved expectation")
        
        var retrievedUsers: [User]? = nil
        cache.fetchItems(for: url) { users in
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on main thread by default",
                          file: file,
                          line: line)
            retrievedUsers = users
            userArrayRetrieveExpectation.fulfill()
        }
        
        self.wait(for: [userArrayRetrieveExpectation], timeout: 1)
        return retrievedUsers
    }
    
    private func removeUserOrUsers(for url: URL,
                                   from cache: UserCache,
                                   file: StaticString = #file,
                                   line: UInt = #line) {
        let userRemoveExpectation = self.expectation(description: "User remove expectation")
        
        cache.removeItem(for: url) {
            XCTAssertTrue(Thread.isMainThread,
                          "Callback should be on main thread by default",
                          file: file,
                          line: line)
            userRemoveExpectation.fulfill()
        }
        
        self.wait(for: [userRemoveExpectation], timeout: 1)
    }
    
    private func validateStoring(with cache: UserCache,
                                 expectedDirectoryURL directoryURL: URL) throws {
        // Does creating the cache make sure its underlying directory exists?
        XCTAssertTrue(FileManagerHelper.directoryExists(at: directoryURL))
        XCTAssertEqual(try FileManagerHelper.contentsOfDirectory(at: directoryURL).count, 0)
        
        // Store some users and make sure they're stored and can be retrieved
        self.storeUser(self.user1, for: self.user1URL, in: cache)
        
        let user1ExpectedPath = FileSystemPathHelper.path(byAppending: "1", to: directoryURL.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user1ExpectedPath))
        
        guard let fetchedUser1 = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Could not fetch user 1!")
            return
        }
        
        XCTAssertEqual(fetchedUser1, self.user1)
        
        self.storeUser(self.user2, for: self.user2URL, in: cache)
        
        let user2ExpectedPath = FileSystemPathHelper.path(byAppending: "2", to: directoryURL.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user2ExpectedPath))
        
        guard let fetchedUser2 = self.fetchUser(for: self.user2URL, from: cache) else {
            XCTFail("Could not fetch user 2!")
            return
        }
        
        XCTAssertEqual(fetchedUser2, self.user2)
        
        self.storeUser(self.user3, for: self.user3URL, in: cache)
        
        let user3ExpectedPath = FileSystemPathHelper.path(byAppending: "3", to: directoryURL.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        guard let fetchedUser3 = self.fetchUser(for: self.user3URL, from: cache) else {
            XCTFail("Could not fetch user 3!")
            return
        }
        
        XCTAssertEqual(fetchedUser3, self.user3)
        
        // Remove an item and make sure it's gone 
        self.removeUserOrUsers(for: self.user3URL, from: cache)
        
        XCTAssertNil(self.fetchUser(for: self.user3URL, from: cache))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        // Get rid of EVERYTHING
        try cache.clearAll()
        
        // The directory should still exist
        XCTAssertTrue(FileManagerHelper.directoryExists(at: directoryURL))
        
        // But all three users should be removed
        XCTAssertFalse(FileManagerHelper.fileExists(at: user1ExpectedPath))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user2ExpectedPath))
        XCTAssertFalse(FileManagerHelper.fileExists(at: user3ExpectedPath))
        
        // As should anything else in there
        XCTAssertEqual(try FileManagerHelper.contentsOfDirectory(at: directoryURL).count, 0)
    }
    
    private func validateStoringArray(cache: UserCache,
                                      expectedDirectoryURL directoryURL: URL) throws {
        let array = [
            self.user1,
            self.user2,
            self.user3
        ]
        
        self.storeUserArray(array, for: self.allUsersURL, in: cache)
        
        guard let fromStorage = self.fetchUserArray(for: self.allUsersURL, from: cache) else {
            XCTFail("Could not fetch array from storage!")
            return
        }
        
        XCTAssertEqual(fromStorage, array)
        
        let allUsersExpectedPath = FileSystemPathHelper.path(byAppending: "all", to: directoryURL.path)
        XCTAssertTrue(FileManagerHelper.fileExists(at: allUsersExpectedPath))
        
        // Get rid of EVERYTHING
        try cache.clearAll()
        
        // The directory should still exist
        XCTAssertTrue(FileManagerHelper.directoryExists(at: directoryURL))
        
        // But the stored array should be removed
        XCTAssertFalse(FileManagerHelper.fileExists(at: allUsersExpectedPath))
        
        // As should anything else in there
        XCTAssertEqual(try FileManagerHelper.contentsOfDirectory(at: directoryURL).count, 0)
    }
    
    private func validateReplacingItem(cache: UserCache) {
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
    
    
    private func validateReplacingArray(cache: UserCache) {
        let array = [
            self.user1,
            self.user2,
            self.user3
        ]
        
        self.storeUserArray(array, for: self.allUsersURL, in: cache)
        guard let fromStorage = self.fetchUserArray(for: self.allUsersURL, from: cache) else {
            XCTFail("Could not fetch array from storage!")
            return
        }
        
        XCTAssertEqual(fromStorage, array)
        
        let array2 = [
            self.user2
        ]
        
        self.storeUserArray(array2, for: self.allUsersURL, in: cache)
        guard let fromStorage2 = self.fetchUserArray(for: self.allUsersURL, from: cache) else {
            XCTFail("Could not refetch array from storage after replacing it!")
            return
        }
        
        XCTAssertEqual(fromStorage2, array2)
    }
    
    // MARK: - Tests
    
    func testPassingEmptyOrNilStringForSubdirectoryNameCreatesDirectoryWithClassName() {
        let userCacheInDocsPath = FileSystemPathHelper.UserDirectory.documents.pathToSubdirectory(named: "UserCache")
        XCTAssertFalse(FileManagerHelper.directoryExists(at: userCacheInDocsPath))
        _ = UserCache(rootDirectory: .documents, subdirectoryName: "")
        XCTAssertTrue(FileManagerHelper.directoryExists(at: userCacheInDocsPath))
        
        let imageCacheInDocsPath = FileSystemPathHelper.UserDirectory.documents.pathToSubdirectory(named: "ImageCache")
        XCTAssertFalse(FileManagerHelper.directoryExists(at: imageCacheInDocsPath))
        _ = ImageCache(rootDirectory: .documents, subdirectoryName: nil)
        XCTAssertTrue(FileManagerHelper.directoryExists(at: imageCacheInDocsPath))
        
        let imageCacheInCachesPath = FileSystemPathHelper.UserDirectory.caches.pathToSubdirectory(named: "ImageCache")
        XCTAssertFalse(FileManagerHelper.directoryExists(at: imageCacheInCachesPath))
        _ = ImageCache(rootDirectory: .caches, subdirectoryName: "")
        XCTAssertTrue(FileManagerHelper.directoryExists(at: imageCacheInCachesPath))
        
        let userCacheInCachesPath = FileSystemPathHelper.UserDirectory.caches.pathToSubdirectory(named: "UserCache")
        XCTAssertFalse(FileManagerHelper.directoryExists(at: userCacheInCachesPath))
        _ = UserCache(rootDirectory: .caches, subdirectoryName: nil)
        XCTAssertTrue(FileManagerHelper.directoryExists(at: userCacheInCachesPath))
    }
    
    func testStoringInCachesDirectory() throws {
        let usersInCaches = FileSystemPathHelper.UserDirectory.caches.pathToSubdirectory(named: "users")
        let url = URL(fileURLWithPath: usersInCaches)
        
        // Directory should not be there and should have no contents before cache is created.
        XCTAssertFalse(FileManagerHelper.directoryExists(at: url))
        XCTAssertEqual(try FileManagerHelper.contentsOfDirectory(at: url).count, 0)
        
        let cache = UserCache(rootDirectory: .caches, subdirectoryName: "users")
        
        try self.validateStoring(with: cache, expectedDirectoryURL: url)
        try self.validateStoringArray(cache: cache, expectedDirectoryURL: url)
    }
    
    func testStoringInDocumentsDirectory() throws {
        let usersInDocuments = FileSystemPathHelper.UserDirectory.documents.pathToSubdirectory(named: "users")
            
        let url = URL(fileURLWithPath: usersInDocuments)
        
        // Directory should not be there and should have no contents before cache is created.
        XCTAssertFalse(FileManagerHelper.directoryExists(at: url))
        XCTAssertEqual(try FileManagerHelper.contentsOfDirectory(at: url).count, 0)
        
        let cache = UserCache(rootDirectory: .documents, subdirectoryName: "users")
        
        try self.validateStoring(with: cache, expectedDirectoryURL: url)
        try self.validateStoringArray(cache: cache, expectedDirectoryURL: url)
    }
    
    func testReplacingExistingStoredItemInCaches() {
        let cache = UserCache(rootDirectory: .caches, subdirectoryName: "users")
        self.validateReplacingItem(cache: cache)
        self.validateReplacingArray(cache: cache)
    }
    
    func testReplacingExistingStoredItemInDocuments() {
        let cache = UserCache(rootDirectory: .documents, subdirectoryName: "users")
        self.validateReplacingItem(cache: cache)
        self.validateReplacingArray(cache: cache)
    }
    
    func testCallingBackOnNonMainQueue() {
        let queue = DispatchQueue(label: "testQueue", qos: .userInitiated, attributes: [.concurrent])
        
        let cache = UserCache(rootDirectory: .documents, subdirectoryName: "users")
        
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
        let cache = UserCache(rootDirectory: .documents, subdirectoryName: "users")
        
        // Store, but don't wait for the completion to fire before trying to grab it again.
        cache.store(item: self.user1, for: self.user1URL)
        
        let fetchedUser = self.fetchUser(for: self.user1URL, from: cache)
        XCTAssertEqual(fetchedUser, self.user1)
    }
    
    func testRemovingWithoutWaitingDoesReturnCachedItem() {
        let cache = UserCache(rootDirectory: .documents, subdirectoryName: "users")
        
        self.storeUser(self.user1, for: self.user1URL, in: cache)
        guard let initialFetchedUser = self.fetchUser(for: self.user1URL, from: cache) else {
            XCTFail("Initial user was not stored!")
            return
        }
        
        XCTAssertEqual(initialFetchedUser, self.user1)
        
        // Remove, but don't wait for the completion to fire before trying to grab it again.
        cache.removeItem(for: self.user1URL)
        
        let fetchedUser = self.fetchUser(for: self.user1URL, from: cache)
        XCTAssertNil(fetchedUser)
    }
}
