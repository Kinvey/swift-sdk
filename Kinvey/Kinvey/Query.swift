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
public class Query: NSObject, BuilderType {
    
    /// Fields to be included in the results of the query.
    internal var fields: Set<String>?
    
    /// `NSPredicate` used to filter records.
    public var predicate: NSPredicate?
    
    /// Array of `NSSortDescriptor`s used to sort records.
    public var sortDescriptors: [NSSortDescriptor]?
    
    /// Skip a certain amount of records in the results of the query.
    public var skip: Int?
    
    /// Impose a limit of records in the results of the query.
    public var limit: Int?
    
    private func translateExpression(expression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .KeyPathExpressionType:
            var keyPath = expression.keyPath
            var persistableType = self.persistableType
            if keyPath.containsString(".") {
                var keyPaths = [String]()
                for item in keyPath.componentsSeparatedByString(".") {
                    keyPaths.append(persistableType?.propertyMapping(item) ?? item)
                    if let persistableTypeTmp = persistableType {
                        persistableType = ObjCRuntime.typeForPropertyName(persistableTypeTmp as! AnyClass, propertyName: item) as? Persistable.Type
                    }
                }
                keyPath = keyPaths.joinWithSeparator(".")
            } else if let translatedKeyPath = persistableType?.propertyMapping(keyPath) {
                keyPath = translatedKeyPath
            }
            return NSExpression(forKeyPath: keyPath)
        default:
            return expression
        }
    }
    
    private func translatePredicate(predicate: NSPredicate) -> NSPredicate {
        if let predicate = predicate as? NSComparisonPredicate {
            return NSComparisonPredicate(
                leftExpression: translateExpression(predicate.leftExpression),
                rightExpression: translateExpression(predicate.rightExpression),
                modifier: predicate.comparisonPredicateModifier,
                type: predicate.predicateOperatorType,
                options: predicate.options
            )
        } else if let predicate = predicate as? NSCompoundPredicate {
            var subpredicates = [NSPredicate]()
            for predicate in predicate.subpredicates as! [NSPredicate] {
                subpredicates.append(translatePredicate(predicate))
            }
            return NSCompoundPredicate(type: predicate.compoundPredicateType, subpredicates: subpredicates)
        }
        return predicate
    }
    
    func isEmpty() -> Bool {
        return self.predicate == nil && self.sortDescriptors == nil
    }
    
    private var queryStringEncoded: String? {
        get {
            if let predicate = predicate {
                let translatedPredicate = translatePredicate(predicate)
                let queryObj = try! MongoDBPredicateAdaptor.queryDictFromPredicate(translatedPredicate)
                
                let data = try! NSJSONSerialization.dataWithJSONObject(queryObj, options: [])
                var queryStr = String(data: data, encoding: NSUTF8StringEncoding)!
                queryStr = queryStr.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
                return queryStr.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
            }
            
            return nil
        }
    }
    
    internal var queryParams: [String : String] {
        get {
            var queryParams = [String : String]()
            
            if let queryParam = queryStringEncoded where !queryParam.isEmpty {
                queryParams["query"] = queryParam
            }
            
            if let sortDescriptors = sortDescriptors {
                var sorts = [String : Int]()
                for sortDescriptor in sortDescriptors {
                    sorts[sortDescriptor.key!] = sortDescriptor.ascending ? 1 : -1
                }
                let data = try! NSJSONSerialization.dataWithJSONObject(sorts, options: [])
                queryParams["sort"] = String(data: data, encoding: NSUTF8StringEncoding)!.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            }
            
            if let fields = fields {
                queryParams["fields"] = fields.joinWithSeparator(",").stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            }
            
            if let skip = skip {
                queryParams["skip"] = String(skip)
            }
            
            if let limit = limit {
                queryParams["limit"] = String(limit)
            }
            
            return queryParams
        }
    }
    
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
    public override convenience required init() {
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
    
    /// Copy Constructor.
    public convenience init(_ query: Query) {
        self.init() {
            $0.fields = query.fields
            $0.predicate = query.predicate
            $0.sortDescriptors = query.sortDescriptors
            $0.skip = query.skip
            $0.limit = query.limit
        }
    }
    
    /// Copy Constructor.
    public convenience init(_ query: Query, @noescape _ block: ((Query) -> Void)) {
        self.init(query)
        block(self)
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

extension Dictionary where Key: StringLiteralConvertible, Value: StringLiteralConvertible {
    
    internal var urlQueryEncoded: String {
        get {
            var queryParams = [String]()
            for keyValuePair in self {
                queryParams.append("\(keyValuePair.0)=\(keyValuePair.1)")
            }
            return queryParams.joinWithSeparator("&")
        }
    }
    
}

@objc(__KNVQuery)
internal class __KNVQuery: NSObject {
    
    class func query(query: Query, persistableType: Persistable.Type) -> Query {
        return Query(query: query, persistableType: persistableType)
    }
    
}
