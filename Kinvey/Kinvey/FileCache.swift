//
//  FileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

protocol FileCache {
    
    associatedtype FileType: File
    
    func save(_ file: FileType, beforeSave: (() -> Void)?)
    
    func remove(_ file: FileType)
    
    func get(_ fileId: String) -> FileType?
    
    func find(_ query: Query) -> AnyRandomAccessCollection<FileType>
    
}

extension FileCache {
    
    func eraseToAnyFileCache() -> AnyFileCache<Self.FileType> {
        return AnyFileCache(self)
    }
    
}

class AnyFileCache<T: File>: FileCache {
    
    typealias FileType = T
    
    private let _save: (T, (() -> Void)?) -> Void
    private let _remove: (T) -> Void
    private let _get: (String) -> T?
    private let _find: (Query) -> AnyRandomAccessCollection<T>
    
    let cache: Any
    
    init<Cache: FileCache>(_ cache: Cache) where Cache.FileType == T {
        self.cache = cache
        _save = cache.save(_:beforeSave:)
        _remove = cache.remove(_:)
        _get = cache.get(_:)
        _find = cache.find(_:)
    }
    
    func save(_ file: T, beforeSave: (() -> Void)?) {
        return _save(file, beforeSave)
    }
    
    func remove(_ file: T) {
        _remove(file)
    }
    
    func get(_ fileId: String) -> T? {
        return _get(fileId)
    }
    
    func find(_ query: Query) -> AnyRandomAccessCollection<T> {
        return _find(query)
    }
    
}
