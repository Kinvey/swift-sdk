//
//  MultipleRandomAccessCollection.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-05-15.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

struct MultipleRandomAccessCollection<T>: RandomAccessCollection {
    
    typealias Element = T
    typealias Index = Array<T>.Index
    typealias SubSequence = Array<T>.SubSequence
    typealias Indices = Array<T>.Indices
    
    let begin: AnyRandomAccessCollection<T>
    let end: AnyRandomAccessCollection<T>
    
    init<C1, C2>(_ begin: C1, _ end: C2) where C1: RandomAccessCollection, C2: RandomAccessCollection, C1.Element == T, C2.Element == T {
        self.begin = AnyRandomAccessCollection(begin)
        self.end = AnyRandomAccessCollection(end)
    }
    
    var startIndex: Index {
        return 0
    }
    
    var endIndex: Index {
        return begin.count + end.count
    }
    
    subscript(position: Index) -> T {
        if position < begin.count {
            return begin[AnyIndex(position)]
        } else {
            return end[AnyIndex(position - begin.count)]
        }
    }
    
}
