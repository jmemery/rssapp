//
//  CacheManager.swift
//  RssReader
//
//  A shared cache manager for storing media assets such as images
//
//  Created by Simon Ng on 19/6/15.
//  Copyright (c) 2015 AppCoda Limited. All rights reserved.
//

import Foundation

class CacheManager: NSObject {
    private(set) var cache = NSCache()
    
    override init() {
        super.init()
        
        configure()
    }
    
    private func configure() {
        // Configure the cache
        cache.countLimit = 500
    }
    
    class func sharedCacheManager() -> CacheManager {
        return shareCacheManager
    }
    
}

let shareCacheManager: CacheManager = { CacheManager() }()