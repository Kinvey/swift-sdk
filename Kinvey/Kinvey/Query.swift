//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// Class that represents a query including filters and sorts.
@objc(KNVQuery)
public class Query: NSObject {
    
    /// `NSPredicate` used to filter records.
    public var predicate: NSPredicate?
    
    /// Array of `NSSortDescriptor`s used to sort records.
    public var sortDescriptors: [NSSortDescriptor]?
    
    var persistableType: Persistable.Type?
    
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, persistableType: Persistable.Type? = nil) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.persistableType = persistableType
    }
    
    convenience init(query: Query, persistableType: Persistable.Type) {
        self.init(predicate: query.predicate, sortDescriptors: query.sortDescriptors, persistableType: persistableType)
    }
    
    /// Default Constructor.
    public override convenience init() {
        self.init(predicate: nil, sortDescriptors: nil, persistableType: nil)
    }
    
    /// Constructor using a `NSPredicate` to filter records.
    public convenience init(predicate: NSPredicate) {
        self.init(predicate: predicate, sortDescriptors: nil, persistableType: nil)
    }
    
    /// Constructor using an array of `NSSortDescriptor`s to sort records.
    public convenience init(sortDescriptors: [NSSortDescriptor]) {
        self.init(predicate: nil, sortDescriptors: sortDescriptors, persistableType: nil)
    }
    
    /// Constructor using a `NSPredicate` to filter records and an array of `NSSortDescriptor`s to sort records.
    public convenience init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]? = nil) {
        self.init(predicate: predicate, sortDescriptors: sortDescriptors, persistableType: nil)
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, _ args: AnyObject...) {
        self.init(format: format, argumentArray: args)
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, args: CVarArgType) {
        self.init(predicate: NSPredicate(format: format, args))
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, argumentArray: [AnyObject]?) {
        self.init(predicate: NSPredicate(format: format, argumentArray: argumentArray))
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, arguments: CVaListPointer) {
        self.init(predicate: NSPredicate(format: format, arguments: arguments))
    }
    
    let sortLock = NSLock()
    
    private func addSort(property: String, ascending: Bool) {
        sortLock.lock()
        if sortDescriptors == nil {
            sortDescriptors = []
        }
        sortLock.unlock()
        sortDescriptors!.append(NSSortDescriptor(key: property, ascending: ascending))
    }
    
    /// Adds ascending properties to be sorted.
    public func ascending(properties: String...) {
        for property in properties {
            addSort(property, ascending: true)
        }
    }
    
    /// Adds descending properties to be sorted.
    public func descending(properties: String...) {
        for property in properties {
            addSort(property, ascending: false)
        }
    }

}

@objc(__KNVQuery)
internal class __KNVQuery: NSObject {
    
    class func query(query: Query, persistableType: Persistable.Type) -> Query {
        return Query(query: query, persistableType: persistableType)
    }
    
}
