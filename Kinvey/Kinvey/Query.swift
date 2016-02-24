//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

@objc(KNVQuery)
public class Query: NSObject {
    
    public var predicate: NSPredicate?
    public var sortDescriptors: [NSSortDescriptor]?
    var persistableClass: Persistable.Type!
    
    public init(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
    }
    
    public convenience init(format: String, _ args: AnyObject...) {
        self.init(format: format, argumentArray: args)
    }
    
    public convenience init(format: String, args: CVarArgType) {
        self.init(predicate: NSPredicate(format: format, args))
    }
    
    public convenience init(format: String, argumentArray: [AnyObject]?) {
        self.init(predicate: NSPredicate(format: format, argumentArray: argumentArray))
    }
    
    public convenience init(format: String, arguments: CVaListPointer) {
        self.init(predicate: NSPredicate(format: format, arguments: arguments))
    }

}
