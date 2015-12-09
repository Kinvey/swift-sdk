//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Query: NSObject {
    
    private var _predicate: NSPredicate!
    
    public var predicate: NSPredicate {
        get {
            return _predicate
        }
    }
    
    public override init() {
        _predicate = NSPredicate()
    }
    
    public init(predicate: NSPredicate) {
        _predicate = predicate
    }
    
    public init(format: String, args: CVarArgType) {
        _predicate = NSPredicate(format: format, args)
    }
    
    public init(format: String, argumentArray: [AnyObject]?) {
        _predicate = NSPredicate(format: format, argumentArray: argumentArray)
    }
    
    public init(format: String, arguments: CVaListPointer) {
        _predicate = NSPredicate(format: format, arguments: arguments)
    }

}
