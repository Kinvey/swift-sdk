//
//  RealmResults.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class Results<T: Object>: NSFastEnumeration, CollectionType {
    
    typealias Generator = RealmSwift.Results<T>.Generator
    typealias SubSequence = RealmSwift.Results<T>.SubSequence
    typealias Index = RealmSwift.Results<T>.Index
    typealias _Element = RealmSwift.Results<T>._Element
    
    let results: RealmSwift.Results<T>
    
    init(_ results: RealmSwift.Results<T>) {
        self.results = results
    }
    
    var count: Int {
        return results.count
    }
    
    @objc func countByEnumeratingWithState(state: UnsafeMutablePointer<NSFastEnumerationState>, objects buffer: AutoreleasingUnsafeMutablePointer<AnyObject?>, count len: Int) -> Int {
        return results.countByEnumeratingWithState(state, objects: buffer, count: len)
    }
    
    var startIndex: Index {
        get {
            return results.startIndex
        }
    }
    
    var endIndex: Index {
        get {
            return results.endIndex
        }
    }
    
    subscript (position: Index) -> _Element {
        get {
            return results[position]
        }
    }
    
    func generate() -> Generator {
        return results.generate()
    }
    
    subscript (bounds: Range<Index>) -> SubSequence {
        get {
            return results[bounds]
        }
    }
    
    func prefixUpTo(end: Index) -> SubSequence {
        return results.prefixUpTo(end)
    }
    
    func suffixFrom(start: Index) -> SubSequence {
        return results.suffixFrom(start)
    }
    
    func prefixThrough(position: Index) -> SubSequence {
        return results.prefixThrough(position)
    }
    
    var isEmpty: Bool {
        get {
            return results.isEmpty
        }
    }
    
    var first: Generator.Element? {
        get {
            return results.first
        }
    }
    
}
