//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper
#if !os(watchOS)
    import MapKit
#endif

extension NSPredicate: StaticMappable {
    
    var json: JsonDictionary? {
        return mongoDBQuery
    }
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return nil
    }
    
    public func mapping(map: Map) {
        if let json = json {
            for (key, var value) in json {
                value <- map[key]
            }
        }
    }
    
}

/// Class that represents a query including filters and sorts.
public final class Query: NSObject, BuilderType, Mappable {
    
    /// Fields to be included in the results of the query.
    open var fields: Set<String>?
    
    /// `NSPredicate` used to filter records.
    open var predicate: NSPredicate?
    
    /// Array of `NSSortDescriptor`s used to sort records.
    open var sortDescriptors: [NSSortDescriptor]?
    
    /// Skip a certain amount of records in the results of the query.
    open var skip: Int?
    
    /// Impose a limit of records in the results of the query.
    open var limit: Int?
    
    public override var description: String {
        return "Fields: \(String(describing: fields))\nPredicate: \(String(describing: predicate))\nSort Descriptors: \(String(describing: sortDescriptors))\nSkip: \(String(describing: skip))\nLimit: \(String(describing: limit))"
    }
    
    internal func translate(expression: NSExpression, otherSideExpression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .keyPath:
            var keyPath = expression.keyPath
            var persistableType = self.persistableType
            if keyPath.contains(".") {
                var keyPaths = [String]()
                for item in keyPath.components(separatedBy: ".") {
                    if let (keyPath, _) = persistableType?.propertyMapping(item) {
                        keyPaths.append(keyPath)
                    } else {
                        keyPaths.append(item)
                    }
                    if let persistableTypeTmp = persistableType {
                        persistableType = ObjCRuntime.typeForPropertyName(persistableTypeTmp as! AnyClass, propertyName: item) as? Persistable.Type
                    }
                }
                keyPath = keyPaths.joined(separator: ".")
            } else if let (translatedKeyPath, _) = persistableType?.propertyMapping(keyPath) {
                keyPath = translatedKeyPath
            }
            return NSExpression(forKeyPath: keyPath)
        case .constantValue:
            #if !os(watchOS)
                if otherSideExpression.expressionType == .keyPath,
                    let (_, optionalTransform) = persistableType?.propertyMapping(otherSideExpression.keyPath),
                    let transform = optionalTransform,
                    let constantValue = expression.constantValue,
                    !(constantValue is MKShape)
                {
                    return NSExpression(forConstantValue: transform.transformToJSON(expression.constantValue))
                }
            #else
                if otherSideExpression.expressionType == .keyPath,
                    let (_, optionalTransform) = persistableType?.propertyMapping(otherSideExpression.keyPath),
                    let transform = optionalTransform
                {
                    return NSExpression(forConstantValue: transform.transformToJSON(expression.constantValue))
                }
            #endif
            return expression
        default:
            return expression
        }
    }
    
    fileprivate func translate(predicate: NSPredicate) -> NSPredicate {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
        }
        if let predicate = predicate as? NSComparisonPredicate {
            return NSComparisonPredicate(
                leftExpression: translate(expression: predicate.leftExpression, otherSideExpression: predicate.rightExpression),
                rightExpression: translate(expression: predicate.rightExpression, otherSideExpression: predicate.leftExpression),
                modifier: predicate.comparisonPredicateModifier,
                type: predicate.predicateOperatorType,
                options: predicate.options
            )
        } else if let predicate = predicate as? NSCompoundPredicate {
            var subpredicates = [NSPredicate]()
            for predicate in predicate.subpredicates as! [NSPredicate] {
                subpredicates.append(translate(predicate: predicate))
            }
            return NSCompoundPredicate(type: predicate.compoundPredicateType, subpredicates: subpredicates)
        }
        return predicate
    }
    
    var isEmpty: Bool {
        return predicate == nil &&
            (sortDescriptors == nil || sortDescriptors!.isEmpty) &&
            skip == nil &&
            limit == nil &&
            (fields == nil || fields!.isEmpty)
    }
    
    fileprivate var queryStringEncoded: String? {
        guard let predicate = predicate else {
            return nil
        }
        
        let translatedPredicate = translate(predicate: predicate)
        let queryObj = translatedPredicate.mongoDBQuery!
        
        let data = try! JSONSerialization.data(withJSONObject: queryObj)
        let queryStr = String(data: data, encoding: String.Encoding.utf8)!
        return queryStr.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    internal var urlQueryItems: [URLQueryItem]? {
        var queryParams = [URLQueryItem]()
        
        if let queryParam = queryStringEncoded, !queryParam.isEmpty {
            let queryItem = URLQueryItem(name: "query", value: queryParam)
            queryParams.append(queryItem)
        }
        
        if let sortDescriptors = sortDescriptors {
            var sorts = [String : Int]()
            for sortDescriptor in sortDescriptors {
                sorts[sortDescriptor.key!] = sortDescriptor.ascending ? 1 : -1
            }
            let data = try! JSONSerialization.data(withJSONObject: sorts)
            let queryItem = URLQueryItem(name: "sort", value: String(data: data, encoding: String.Encoding.utf8)!)
            queryParams.append(queryItem)
        }
        
        if let fields = fields {
            let queryItem = URLQueryItem(name: "fields", value: fields.joined(separator: ","))
            queryParams.append(queryItem)
        }
        
        if let skip = skip {
            let queryItem = URLQueryItem(name: "skip", value: String(skip))
            queryParams.append(queryItem)
        }
        
        if let limit = limit {
            let queryItem = URLQueryItem(name: "limit", value: String(limit))
            queryParams.append(queryItem)
        }
        
        return queryParams.count > 0 ? queryParams : nil
    }
    
    var persistableType: Persistable.Type?
    
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, persistableType: Persistable.Type? = nil) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.persistableType = persistableType
    }
    
    convenience init(query: Query, persistableType: Persistable.Type) {
        self.init(query) {
            $0.persistableType = persistableType
        }
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
    public convenience init(format: String, _ args: Any...) {
        self.init(format: format, argumentArray: args)
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, args: CVarArg) {
        self.init(predicate: NSPredicate(format: format, args))
    }
    
    /// Constructor using a similar way to construct a `NSPredicate`.
    public convenience init(format: String, argumentArray: [Any]?) {
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
            $0.persistableType = query.persistableType
        }
    }
    
    /// Copy Constructor.
    public convenience init(_ query: Query, _ block: ((Query) -> Void)) {
        self.init(query)
        block(self)
    }
    
    public init?(map: Map) {
        return nil
    }
    
    let sortLock = NSLock()
    
    fileprivate func addSort(_ property: String, ascending: Bool) {
        sortLock.lock()
        if sortDescriptors == nil {
            sortDescriptors = []
        }
        sortLock.unlock()
        sortDescriptors!.append(NSSortDescriptor(key: property, ascending: ascending))
    }
    
    /// Adds ascending properties to be sorted.
    open func ascending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: true)
        }
    }
    
    /// Adds descending properties to be sorted.
    open func descending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: false)
        }
    }
    
    public func mapping(map: Map) {
        if map.mappingType == .toJSON, let predicate = predicate {
            predicate.mapping(map: map)
        }
    }

}
