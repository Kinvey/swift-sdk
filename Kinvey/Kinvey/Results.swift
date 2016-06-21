//
//  RealmResults.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

public class Results<T: Object>: NSFastEnumeration, CollectionType {
    
    public typealias Generator = RealmSwift.Results<T>.Generator
    public typealias SubSequence = RealmSwift.Results<T>.SubSequence
    public typealias Index = RealmSwift.Results<T>.Index
    public typealias _Element = RealmSwift.Results<T>._Element
    
    let results: RealmSwift.Results<T>
    
    init(_ results: RealmSwift.Results<T>) {
        self.results = results
    }
    
    public var count: Int {
        return results.count
    }
    
    @objc public func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int {
        return results.countByEnumeratingWithState(state, objects: buffer, count: len)
    }
    
    public var startIndex: Index {
        get {
            return results.startIndex
        }
    }
    
    public var endIndex: Index {
        get {
            return results.endIndex
        }
    }
    
    public subscript (position: Index) -> _Element {
        get {
            return results[position]
        }
    }
    
    public func generate() -> Generator {
        return results.generate()
    }
    
    public subscript (bounds: Range<Index>) -> SubSequence {
        get {
            return results[bounds]
        }
    }
    
    public func prefixUpTo(end: Index) -> SubSequence {
        return results.prefixUpTo(end)
    }
    
    public func suffixFrom(start: Index) -> SubSequence {
        return results.suffixFrom(start)
    }
    
    public func prefixThrough(position: Index) -> SubSequence {
        return results.prefixThrough(position)
    }
    
    public var isEmpty: Bool {
        get {
            return results.isEmpty
        }
    }
    
    public var first: Generator.Element? {
        get {
            return results.first
        }
    }
    
}
