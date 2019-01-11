# Cache Me If You Can

## What?

Lightweight, type-safe caching based on `URL`s in Swift. 

## Why? 

We're focusing on something we have to do a lot: Load data from a `URL` that will not change, such as a PDF file or an image, so that it can be cached locally. In cases like this, if the image or file is changed by a user or an admin, then a new `URL` is returned rather than new data being returned by the same URL. 

Far more often than not, we've found you *can* make the assumption that the data at a given URL will not change, but most existing libraries for caching on iOS don't make this assumption. **If you can't assume data at the same `URL` will always be the same, you should use another library for caching**. 

However, if you *can* make that assumption, caching logic can be *way* simpler. That's why we built this library.

We do: 

- Caching objects in memory or to the file system based on a `URL`
- Specification and enforcement of callback `DispatchQueue`s
- Individual or wholesale item removal from the cache

We **don't** do: 

- HTTP-based caching
- Time-based expiration
- Automatic re-fetching if the contents of the URL have changed
- Automatic invalidation if the contents of the URL have been removed

## How? 

Generics and Enums and Protocols! This is basically not usable from Obj-C without writing a wrapper. 😜

The main useful classes are:

### [`FileSystemDataCache`](CacheMeIfYouCan/CacheMeIfYouCan/CacheTypes/FileSystemDataCache.swift)

A cache which stores data from [`DataConvertible`](CacheMeIfYouCan/CacheMeIfYouCan/Protocols/DataConvertible.swift) types on the filesystem - ie, anything which you declare can be optionally converted to `Data`. 

Also includes: 

- Downloading items from the given URL if they are not present in the filesystem
- The [`DataConvertibleCodable`](CacheMeIfYouCan/CacheMeIfYouCan/Protocols/DataConvertibleCodable.swift) protocol to make it really easy to store any `Codable` objects using one of these caches. See [`UserCache`](CacheMeIfYouCan/CacheMeIfYouCanTests/TestCacheTypes/UserCache.swift) in the tests for an example of how to implement this. 


#### [`ImageCache`](CacheMeIfYouCan/CacheMeIfYouCan/CacheTypes/ImageCache.swift)

Since this is one of the main things we built this for, we've included a `UIImage`-specific version of the `FileSystemDataCache` to save everyone the trouble of making their own.

### [`InMemoryCache`](CacheMeIfYouCan/CacheMeIfYouCan/CacheTypes/InMemoryCache.swift)

A cache which stores `AnyObject` and any conforming types in-memory using an underlying `NSCache`.

Note: This cache does **not** automatically handle downloading since `Data` is actually a `struct`. 

### [`DownloadHelper`](CacheMeIfYouCan/CacheMeIfYouCan/Helpers/DownloadHelper.swift)

A simple `URLSession`-based wrapper to fetch `Data` from a single `URL` and call back on a given queue, and throw basic errors if it fails.

## When? 

RIGHT NOW!

## Who? 

This project is sponsored by [Bakken & Bæck](https://bakkenbaeck.no), but specifically, contributors include: 
    
- [Ellen Shapiro](https://github.com/designatednerd)
- You? Open a PR!

Shout out to [Colin Dodd](https://github.com/csdodd) for naming this library.