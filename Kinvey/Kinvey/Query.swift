//
//  Query.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
#if !os(watchOS)
    import MapKit
#endif

/// Class that represents a query including filters and sorts.
public final class Query: NSObject, BuilderType {
    
    /// Fields to be included in the results of the query.
    public var fields: Set<String>?
    
    internal var fieldsAsString: String? {
        return fields?.sorted().joined(separator: ",")
    }
    
    /// `NSPredicate` used to filter records.
    public var predicate: NSPredicate?
    
    internal var predicateAsString: String? {
        return predicate.map({ String(describing: $0) })
    }
    
    /// Array of `NSSortDescriptor`s used to sort records.
    public var sortDescriptors: [NSSortDescriptor]?
    
    /// Skip a certain amount of records in the results of the query.
    public var skip: Int?
    
    /// Impose a limit of records in the results of the query.
    public var limit: Int?
    
    internal var emptyPredicateMustReturnNil = true
    
    public override var description: String {
        return "Fields: \(String(describing: fields))\nPredicate: \(String(describing: predicate))\nSort Descriptors: \(String(describing: sortDescriptors))\nSkip: \(String(describing: skip))\nLimit: \(String(describing: limit))"
    }
    
    internal func translate(expression: NSExpression, otherSideExpression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .keyPath:
            var keyPath = expression.keyPath
            var type: AnyClass? = self.persistableType as? AnyClass
            if keyPath.contains(".") {
                var keyPaths = [String]()
                for item in keyPath.components(separatedBy: ".") {
                    if let persistableType = type as? Persistable.Type,
                        let (keyPath, _) = persistableType.propertyMapping(item)
                    {
                        keyPaths.append(keyPath)
                    } else if let type = type, let objectType = type as? NSObject.Type, type is BaseMappable.Type {
                        let className = StringFromClass(cls: type)
                        if kinveyProperyMapping[className] == nil {
                            currentMappingClass = className
                            mappingOperationQueue.addOperation {
                                if kinveyProperyMapping[className] == nil {
                                    kinveyProperyMapping[className] = PropertyMap()
                                }
                                let obj = objectType.init()
                                let _ = (obj as! BaseMappable).toJSON()
                            }
                            mappingOperationQueue.waitUntilAllOperationsAreFinished()
                        }
                        if let kinveyMappingClassType = kinveyProperyMapping[className],
                            let (keyPath, _) = kinveyMappingClassType[item]
                        {
                            keyPaths.append(keyPath)
                        } else {
                            keyPaths.append(item)
                        }
                    } else {
                        keyPaths.append(item)
                    }
                    if let _type = type {
                        type = ObjCRuntime.typeForPropertyName(_type, propertyName: item)
                    }
                }
                keyPath = keyPaths.joined(separator: ".")
            } else if let persistableType = type as? Persistable.Type, let (translatedKeyPath, _) = persistableType.propertyMapping(keyPath) {
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
        signpost(.begin, log: osLog, name: "Translate Query")
        defer {
            signpost(.end, log: osLog, name: "Translate Query")
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
            return emptyPredicateMustReturnNil ? nil : "{}"
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
    
    init(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fields: Set<String>? = nil,
        persistableType: Persistable.Type? = nil
    ) {
        self.predicate = predicate
        self.sortDescriptors = sortDescriptors
        self.fields = fields
        self.persistableType = persistableType
    }
    
    convenience init(query: Query, persistableType: Persistable.Type) {
        self.init(query) {
            $0.persistableType = persistableType
        }
    }
    
    /// Default Constructor.
    public override convenience required init() {
        self.init(
            predicate: nil,
            sortDescriptors: nil,
            fields: nil,
            persistableType: nil
        )
    }
    
    /// Constructor using a `NSPredicate` to filter records, an array of `NSSortDescriptor`s to sort records and the fields that should be returned.
    public convenience init(
        predicate: NSPredicate? = nil,
        sortDescriptors: [NSSortDescriptor]? = nil,
        fields: Set<String>? = nil
    ) {
        self.init(
            predicate: predicate,
            sortDescriptors: sortDescriptors,
            fields: fields,
            persistableType: nil
        )
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
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
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
    public func ascending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: true)
        }
    }
    
    /// Adds descending properties to be sorted.
    public func descending(_ properties: String...) {
        for property in properties {
            addSort(property, ascending: false)
        }
    }

}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension Query: Mappable {
    
    public func mapping(map: Map) {
        if map.mappingType == .toJSON, let predicate = predicate {
            predicate.mapping(map: map)
        }
    }
    
}
