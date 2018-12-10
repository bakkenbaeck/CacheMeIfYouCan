//
//  FilesystemDataCache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/10/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

open class FileSystemDataCache<StoredType: DataConvertible>: Cache<StoredType> {
    
    let folderURL: URL
    
    init(folderURL: URL) {
        self.folderURL = folderURL
    }
    
    private func localURL(for url: URL) -> URL {
        let fileName = FilesystemPathHelper.fileName(from: url)
        return self.folderURL
            .appendingPathComponent(fileName)
    }
    
    open override func actuallyStore(item: StoredType, for url: URL) throws {
        guard let data = item.toData else {
            return
        }
        
        let url = self.localURL(for: url)
        try data.write(to: url)
    }
    
    open override func actuallyFetchItem(for url: URL) throws -> StoredType? {
        let url = self.localURL(for: url)
       
        let data = try Data(contentsOf: url)
        let item = StoredType(data: data)
        
        return item
    }
}
