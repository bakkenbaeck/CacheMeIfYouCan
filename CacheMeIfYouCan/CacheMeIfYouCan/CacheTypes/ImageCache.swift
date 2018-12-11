//
//  ImageCache.swift
//  CacheMeIfYouCan
//
//  Created by Ellen Shapiro on 12/11/18.
//  Copyright © 2018 Bakken & Baeck. All rights reserved.
//

import Foundation

extension UIImage: DataConvertible {
    
    public var toData: Data? {
        return self.pngData()
    }
    
    // UIImage already has a failable initializer with data, so no need to override.
}

open class ImageCache: FileSystemDataCache<UIImage> {}
