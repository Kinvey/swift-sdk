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

#if canImport(os)
    import os
#endif

#if canImport(MongoDBPredicateAdaptor)
    import MongoDBPredicateAdaptor
#endif

extension NSPredicate {
    
    internal var asString: String {
        return String(describing: self)
    }
    
}

/// Class that represents a query including filters and sorts.
public final class Query: NSObject, BuilderType {
    
    /// Fields to be included in the results of the query.
    public var fields: Set<String>?
    
    internal var fieldsAsString: String? {
        return fields?.sorted().joined(separator: ",")
    }
    
    /// `NSPredicate` used to filter records.
    public var predicate: NSPredicate? {
        get {
            guard let predicateKind = predicateKind else {
                return nil
            }
            switch predicateKind {
            case .predicate(let predicate):
                return predicate
            case .booleanExpression(let booleanExpression):
                return booleanExpression.expression.predicate
            }
        }
        set {
            predicateKind = newValue.predicateKind
        }
    }
    
    private var predicateKind: PredicateKind?
    
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
            } else if let persistableType = type as? Persistable.Type,
                let (translatedKeyPath, _) = persistableType.propertyMapping(keyPath)
            {
                keyPath = translatedKeyPath
            } else if let persistableType = type as? Persistable.Type,
                let translatedKeyPath = try? persistableType.translate(property: keyPath)
            {
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
            if let date = expression.constantValue as? Date {
                return NSExpression(forConstantValue: date.toISO8601())
            }
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
        guard let predicateKind = predicateKind else {
            return emptyPredicateMustReturnNil ? nil : "{}"
        }
        
        let queryObj: [String : Any]
        switch predicateKind {
        case .predicate(let predicate):
            let translatedPredicate = translate(predicate: predicate)
            queryObj = translatedPredicate.mongoDBQuery!
        case .booleanExpression(let booleanExpression):
            queryObj = booleanExpression.expression.mongoDBQuery!
        }
        
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
        self.predicateKind = predicate.predicateKind
        self.sortDescriptors = sortDescriptors
        self.fields = fields
        self.persistableType = persistableType
    }
    
    public var booleanExpression: BooleanExpression? {
        get {
            guard let predicateKind = predicateKind else {
                return nil
            }
            switch predicateKind {
            case .booleanExpression(let booleanExpression):
                return booleanExpression
            case .predicate:
                return nil
            }
        }
        set {
            predicateKind = newValue.predicateKind
        }
    }
    
    public init(_ booleanExpression: BooleanExpression) {
        self.predicateKind = .booleanExpression(booleanExpression)
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
    
    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
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
    @discardableResult
    public func ascending(_ properties: String...) -> Query {
        for property in properties {
            addSort(property, ascending: true)
        }
        return self
    }
    
    /// Adds descending properties to be sorted.
    @discardableResult
    public func descending(_ properties: String...) -> Query {
        for property in properties {
            addSort(property, ascending: false)
        }
        return self
    }
    
    @discardableResult
    public func sort<Root, Value>(_ keyPath: KeyPath<Root, Value>, ascending: Bool) -> Query {
        sortLock.lock()
        if sortDescriptors == nil {
            sortDescriptors = []
        }
        sortLock.unlock()
        sortDescriptors!.append(NSSortDescriptor(key: keyPath.name, ascending: ascending))
        return self
    }
    
    /// Adds ascending properties to be sorted.
    @discardableResult
    public func ascending<Root, Value>(_ keyPaths: KeyPath<Root, Value>...) -> Query {
        for keyPath in keyPaths {
            sort(keyPath, ascending: true)
        }
        return self
    }
    
    /// Adds ascending properties to be sorted.
    @discardableResult
    public func descending<Root, Value>(_ keyPaths: KeyPath<Root, Value>...) -> Query {
        for keyPath in keyPaths {
            sort(keyPath, ascending: false)
        }
        return self
    }

}

extension KeyPath {
    
    internal var name: String {
        return NSExpression(forKeyPath: self).keyPath
    }
    
}

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
extension Query: Mappable {
    
    public func mapping(map: Map) {
        if map.mappingType == .toJSON, let predicate = predicate {
            predicate.mapping(map: map)
        }
    }
    
}

public indirect enum Expression {
    
    public typealias ExpressionProducer = () -> Expression
    
    case column(String)
    case and(lhs: Expression, rhs: Expression)
    case or(lhs: Expression, rhs: Expression)
    case equality(lhs: Expression, rhs: Expression)
    case inequality(lhs: Expression, rhs: Expression)
    case not(rhs: Expression)
    case lessThan(lhs: Expression, rhs: Expression)
    case lessThanEqual(lhs: Expression, rhs: Expression)
    case greaterThan(lhs: Expression, rhs: Expression)
    case greaterThanEqual(lhs: Expression, rhs: Expression)
    case `in`(lhs: Expression, rhs: [Expression])
    case like(lhs: Expression, wild1: Bool, String, wild2: Bool)
    case geoIn(lhs: Expression, rhs: Expression)
    case lazy(ExpressionProducer)
    case keyPath(AnyKeyPath, NSExpression)
    
    case integer(Int)
    case uinteger(UInt)
    case integer64(Int64)
    case uinteger64(UInt64)
    case integer32(Int32)
    case uinteger32(UInt32)
    case integer16(Int16)
    case uinteger16(UInt16)
    case integer8(Int8)
    case uinteger8(UInt8)
    
    case double(Double)
    case float(Float)
    case string(String)
    case blob([UInt8])
    case sblob([Int8])
    case bool(Bool)
    case uuid(UUID)
    case date(Date)
    case url(URL)
    case null
    
    #if canImport(MapKit) && !os(watchOS)
    case circle(MKCircle)
    case polygon(MKPolygon)
    #endif
    
}

// MARK: - Mongo DB Query

extension Expression {
    
    var mongoDBQuery: [String : Any]? {
        return transform(expression: self)
    }
    
    var keyPath: String? {
        switch self {
        case .keyPath(_, let expression):
            return expression.keyPath
        default:
            return nil
        }
    }
    
    var value: Any? {
        switch self {
        case .integer(let value as Any),
             .uinteger(let value as Any),
             .integer64(let value as Any),
             .uinteger64(let value as Any),
             .integer32(let value as Any),
             .uinteger32(let value as Any),
             .integer16(let value as Any),
             .uinteger16(let value as Any),
             .integer8(let value as Any),
             .uinteger8(let value as Any),
             .double(let value as Any),
             .float(let value as Any),
             .string(let value as Any),
             .blob(let value as Any),
             .sblob(let value as Any),
             .bool(let value as Any),
             .uuid(let value as Any),
             .date(let value as Any),
             .url(let value as Any):
            return value
        #if canImport(MapKit) && !os(watchOS)
        case .circle(let value as Any),
             .polygon(let value as Any):
            return value
        #endif
        case .null:
            return NSNull()
        default:
            return nil
        }
    }
    
    var lhsMongoDBOperatorRhs: (lhs: Expression, `operator`: MongoDBOperator, rhs: Expression)? {
        switch self {
        case .equality(let lhs, let rhs):
            return (lhs: lhs, operator: .equalTo, rhs: rhs)
        case .inequality(let lhs, let rhs):
            return (lhs: lhs, operator: .notEqualTo, rhs: rhs)
        case .greaterThan(let lhs, let rhs):
            return (lhs: lhs, operator: .greaterThan, rhs: rhs)
        case .greaterThanEqual(let lhs, let rhs):
            return (lhs: lhs, operator: .greaterThanOrEqualTo, rhs: rhs)
        case .lessThan(let lhs, let rhs):
            return (lhs: lhs, operator: .lessThan, rhs: rhs)
        case .lessThanEqual(let lhs, let rhs):
            return (lhs: lhs, operator: .lessThanOrEqualTo, rhs: rhs)
        default:
            return nil
        }
    }
    
    private func transform(lhs: Expression, operator: MongoDBOperator, rhs: Expression, optimize: Bool) -> [String : Any]? {
        let keyPath = lhs.keyPath!
        let value = rhs.value!
        switch (`operator`, optimize) {
        case (MongoDBOperator.equalTo, true):
            return [keyPath : value]
        default:
            return [keyPath : [`operator`.rawValue : value]]
        }
    }
    
    private func transform(expression: Expression, optimize: Bool = true) -> [String : Any]? {
        switch expression {
        case .equality(let lhs, let rhs):
            return transform(lhs: lhs, operator: .equalTo, rhs: rhs, optimize: optimize)
        case .inequality(let lhs, let rhs):
            return transform(lhs: lhs, operator: .notEqualTo, rhs: rhs, optimize: optimize)
        case .greaterThan(let lhs, let rhs):
            return transform(lhs: lhs, operator: .greaterThan, rhs: rhs, optimize: optimize)
        case .greaterThanEqual(let lhs, let rhs):
            return transform(lhs: lhs, operator: .greaterThanOrEqualTo, rhs: rhs, optimize: optimize)
        case .lessThan(let lhs, let rhs):
            return transform(lhs: lhs, operator: .lessThan, rhs: rhs, optimize: optimize)
        case .lessThanEqual(let lhs, let rhs):
            return transform(lhs: lhs, operator: .lessThanOrEqualTo, rhs: rhs, optimize: optimize)
        case .and(let lhs, let rhs):
            let expressions = [
                transform(expression: lhs, optimize: optimize),
                transform(expression: rhs, optimize: optimize)
            ].compactMap { $0 }
            if optimize, expressions.count <= 1 {
                return expressions.first
            }
            if optimize,
                let sequence = Optional(expressions.filter({ $0.count == 1 }).compactMap({ $0.first })),
                expressions.count == Set(sequence.map{ $0.key }).count
            {
                return [String : Any](uniqueKeysWithValues: sequence)
            }
            return [MongoDBOperator.and.rawValue : expressions]
        case .or(let lhs, let rhs):
            return [
                MongoDBOperator.or.rawValue : [
                    transform(expression: lhs, optimize: optimize),
                    transform(expression: rhs, optimize: optimize)
                ]
            ]
        case .not(let rhs):
            if let (lhs, `operator`, rhs) = rhs.lhsMongoDBOperatorRhs,
                let keyPath = lhs.keyPath,
                let value = rhs.value
            {
                return [
                    keyPath : [
                        MongoDBOperator.not.rawValue : [
                            `operator`.rawValue : value
                        ]
                    ]
                ]
            }
            return [MongoDBOperator.not.rawValue : [transform(expression:rhs, optimize: optimize)]]
        case .like(let lhs, let wild1, let value, let wild2):
            let keyPath: String
            switch lhs {
            case .keyPath(_, let expression):
                keyPath = expression.keyPath
            default:
                return nil
            }
            let regexValue: String
            switch (wild1, wild2) {
            case (true, true):
                regexValue = ".*\(value).*"
            case (false, true):
                regexValue = ".*\(value)"
            case (true, false):
                regexValue = "^\(value)"
            default:
                regexValue = value
            }
            return [
                keyPath : [
                    MongoDBOperator.matches.rawValue : regexValue
                ]
            ]
        case .in(let lhs, let rhs):
            let keyPath: String
            switch lhs {
            case .keyPath(_, let expression):
                keyPath = expression.keyPath
            default:
                return nil
            }
            let values = rhs.map { $0.value }
            return [
                keyPath : [
                    MongoDBOperator.in.rawValue : values
                ]
            ]
        case .geoIn(let lhs, let rhs):
            let keyPath: String
            switch lhs {
            case .keyPath(_, let expression):
                keyPath = expression.keyPath
            default:
                return nil
            }
            return [
                keyPath : [
                    MongoDBOperator.geoIn.rawValue : transform(expression: rhs, optimize: optimize)
                ]
            ]
        #if canImport(MapKit) && !os(watchOS)
        case .circle(let circle):
            return [
                "$centerSphere" : [
                    [
                        circle.coordinate.longitude,
                        circle.coordinate.latitude
                    ],
                    circle.radius / 6371000.0
                ]
            ]
        case .polygon(let polygon):
            let pointCount = polygon.pointCount
            var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            polygon.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
            let coordinatesArray = coordinates.map { [$0.longitude, $0.latitude] }
            return [
                "$polygon" : coordinatesArray
            ]
        #endif
        default:
            return [:]
        }
    }
    
}

// MARK: - Expression -> Predicate

extension Expression {
    
    var predicate: NSPredicate? {
        return transform(expression: self)
    }
    
    var expression: NSExpression? {
        switch self {
        case .keyPath(_, let expression):
            return expression
        case .integer(let value as Any),
             .uinteger(let value as Any),
             .integer64(let value as Any),
             .uinteger64(let value as Any),
             .integer32(let value as Any),
             .uinteger32(let value as Any),
             .integer16(let value as Any),
             .uinteger16(let value as Any),
             .integer8(let value as Any),
             .uinteger8(let value as Any),
             .double(let value as Any),
             .float(let value as Any),
             .string(let value as Any),
             .blob(let value as Any),
             .sblob(let value as Any),
             .bool(let value as Any),
             .uuid(let value as Any),
             .date(let value as Any),
             .url(let value as Any):
            return NSExpression(forConstantValue: value)
        #if canImport(MapKit) && !os(watchOS)
        case .circle(let value as Any),
             .polygon(let value as Any):
            return NSExpression(forConstantValue: value)
        #endif
        case .null:
            return NSExpression(forConstantValue: nil)
        default:
            return nil
        }
    }
    
    private func transform(expression: Expression) -> NSPredicate? {
        switch expression {
        case .equality(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .equalTo)
        case .inequality(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .notEqualTo)
        case .greaterThan(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .greaterThan)
        case .greaterThanEqual(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .greaterThanOrEqualTo)
        case .lessThan(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .lessThan)
        case .lessThanEqual(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: rhs.expression!, type: .lessThanOrEqualTo)
        case .and(let lhs, let rhs):
            return NSCompoundPredicate(andPredicateWithSubpredicates: [lhs.predicate!, rhs.predicate!])
        case .or(let lhs, let rhs):
            return NSCompoundPredicate(orPredicateWithSubpredicates: [lhs.predicate!, rhs.predicate!])
        case .not(let rhs):
            return NSCompoundPredicate(notPredicateWithSubpredicate: rhs.predicate!)
        case .like(let lhs, let wild1, let rhs, let wild2):
            let type: NSComparisonPredicate.Operator
            switch (wild1, wild2) {
            case (true, true):
                type = .contains
            case (false, true):
                type = .endsWith
            case (true, false):
                type = .beginsWith
            default:
                return nil
            }
            return transform(lhs: lhs.expression!, rhs: NSExpression(forConstantValue: rhs), type: type)
        case .`in`(let lhs, let rhs):
            return transform(lhs: lhs.expression!, rhs: NSExpression(forConstantValue: rhs.map { $0.expression!.constantValue }), type: .in)
        default:
            return nil
        }
    }
    
    private func transform(
        lhs: NSExpression,
        rhs: NSExpression,
        modifier: NSComparisonPredicate.Modifier = .direct,
        type: NSComparisonPredicate.Operator,
        options: NSComparisonPredicate.Options = []
    ) -> NSComparisonPredicate {
        return NSComparisonPredicate(
            leftExpression: lhs,
            rightExpression: rhs,
            modifier: modifier,
            type: type,
            options: options
        )
    }
    
}

// MARK: - BooleanExpression

public protocol BooleanExpression {
    
    var expression: Expression { get }
    
}

struct BooleanExpressionWrapper: BooleanExpression {
    
    let expression: Expression
    
    init(_ e: Expression) {
        expression = e
    }
    
}

enum PredicateKind {
    
    case predicate(NSPredicate)
    case booleanExpression(BooleanExpression)
    
}

// MARK: - == Operator

public func == <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.equality(lhs: lhs.expression, rhs: rhs.expression))
}

public func == <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.equality(lhs: lhs.expression, rhs: rhs.expression))
}

public func == <Root, Value: GeoValueExpressionType>(lhs: KeyPath<Root, GeoPoint>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.geoIn(lhs: lhs.expression, rhs: rhs.expression))
}

public func == <Root, Value: GeoValueExpressionType>(lhs: KeyPath<Root, GeoPoint?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.geoIn(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - != Operator

public func != <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.inequality(lhs: lhs.expression, rhs: rhs.expression))
}

public func != <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.inequality(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - <> Operator

infix operator <>: ComparisonPrecedence

public func <> <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.inequality(lhs: lhs.expression, rhs: rhs.expression))
}

public func <> <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.inequality(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - < Operator

public func < <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.lessThan(lhs: lhs.expression, rhs: rhs.expression))
}

public func < <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.lessThan(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - <= Operator

public func <= <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.lessThanEqual(lhs: lhs.expression, rhs: rhs.expression))
}

public func <= <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.lessThanEqual(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - > Operator

public func > <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.greaterThan(lhs: lhs.expression, rhs: rhs.expression))
}

public func > <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.greaterThan(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - >= Operator

public func >= <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.greaterThanEqual(lhs: lhs.expression, rhs: rhs.expression))
}

public func >= <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: Value) -> BooleanExpression {
    return BooleanExpressionWrapper(.greaterThanEqual(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - && Operator

public func && (lhs: BooleanExpression, rhs: BooleanExpression) -> BooleanExpression {
    return BooleanExpressionWrapper(.and(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - || Operator

public func || (lhs: BooleanExpression, rhs: BooleanExpression) -> BooleanExpression {
    return BooleanExpressionWrapper(.or(lhs: lhs.expression, rhs: rhs.expression))
}

// MARK: - ! Operator

public prefix func ! (rhs: BooleanExpression) -> BooleanExpression {
    return BooleanExpressionWrapper(.not(rhs: rhs.expression))
}

// MARK: - %=% Operator LIKE CONTAINS

infix operator %=%: ComparisonPrecedence // LIKE %v% . string or regexp or in array

public func %=% <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: true, rhs, wild2: true))
}

public func %=% <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: true, rhs, wild2: true))
}

// MARK: - =% Operator LIKE BEGINS WITH

infix operator =%: ComparisonPrecedence // LIKE v% . string

public func =% <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: true, rhs, wild2: false))
}

public func =% <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: true, rhs, wild2: false))
}

// MARK: - %= Operator LIKE ENDS WITH

public func %= <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: false, rhs, wild2: true))
}

public func %= <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return BooleanExpressionWrapper(.like(lhs: lhs.expression, wild1: false, rhs, wild2: true))
}

// MARK: - !~ Operator NOT LIKE

infix operator %!=%: ComparisonPrecedence // NOT LIKE %v% . string or regexp or array

public func %!=% <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return !(lhs %=% rhs)
}

public func %!=% <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return !(lhs %=% rhs)
}

infix operator !=%: ComparisonPrecedence // NOT LIKE v% . string

public func !=% <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return !(lhs =% rhs)
}

public func !=% <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return !(lhs =% rhs)
}

infix operator %!=: ComparisonPrecedence // NOT LIKE %v . string

public func %!= <Root>(lhs: KeyPath<Root, String>, rhs: String) -> BooleanExpression {
    return !(lhs %= rhs)
}

public func %!= <Root>(lhs: KeyPath<Root, String?>, rhs: String) -> BooleanExpression {
    return !(lhs %= rhs)
}

// MARK: - ~ Operator IN

infix operator ~: ComparisonPrecedence // IN, matches

public func ~ <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: [Value]) -> BooleanExpression {
    return BooleanExpressionWrapper(.in(lhs: lhs.expression, rhs: rhs.map { $0.expression }))
}

public func ~ <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: [Value]) -> BooleanExpression {
    return BooleanExpressionWrapper(.in(lhs: lhs.expression, rhs: rhs.map { $0.expression }))
}

// MARK: - !~ Operator NOT IN

infix operator !~: ComparisonPrecedence // NOT IN, matches

public func !~ <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value>, rhs: [Value]) -> BooleanExpression {
    return !(lhs ~ rhs)
}

public func !~ <Root, Value: ValueExpressionType>(lhs: KeyPath<Root, Value?>, rhs: [Value]) -> BooleanExpression {
    return !(lhs ~ rhs)
}

// MARK: - Expression Types

public protocol ExpressionType {
    
    var expression: Expression { get }
    
}

extension KeyPath: ExpressionType {
    
    public var expression: Expression {
        return .keyPath(self, NSExpression(forKeyPath: self))
    }
    
}

public protocol ValueExpressionType: ExpressionType {
}

public protocol GeoValueExpressionType: ExpressionType {
}

extension Int: ValueExpressionType {
    
    public var expression: Expression {
        return .integer(self)
    }
    
}

extension UInt: ValueExpressionType {
    
    public var expression: Expression {
        return .uinteger(self)
    }
    
}

extension Int64: ValueExpressionType {
    
    public var expression: Expression {
        return .integer64(self)
    }
    
}

extension UInt64: ValueExpressionType {
    
    public var expression: Expression {
        return .uinteger64(self)
    }
    
}

extension Int32: ValueExpressionType {
    
    public var expression: Expression {
        return .integer32(self)
    }
    
}

extension UInt32: ValueExpressionType {
    
    public var expression: Expression {
        return .uinteger32(self)
    }
    
}

extension Int16: ValueExpressionType {
    
    public var expression: Expression {
        return .integer16(self)
    }
    
}

extension UInt16: ValueExpressionType {
    
    public var expression: Expression {
        return .uinteger16(self)
    }
    
}

extension Int8: ValueExpressionType {
    
    public var expression: Expression {
        return .integer8(self)
    }
    
}

extension UInt8: ValueExpressionType {
    
    public var expression: Expression {
        return .uinteger8(self)
    }
    
}

extension Double: ValueExpressionType {
    
    public var expression: Expression {
        return .double(self)
    }
    
}

extension Float: ValueExpressionType {
    
    public var expression: Expression {
        return .float(self)
    }
    
}

extension String: ValueExpressionType {
    
    public var expression: Expression {
        return .string(self)
    }
    
}

extension Array: ValueExpressionType, ExpressionType where Element == UInt8 {
    
    public var expression: Expression {
        return .blob(self)
    }
    
}

extension Array /*: ValueExpressionType, ExpressionType */ where Element == Int8 {
    
    public var expression: Expression {
        return .sblob(self)
    }
    
}

extension Bool: ValueExpressionType {
    
    public var expression: Expression {
        return .bool(self)
    }
    
}

extension UUID: ValueExpressionType {
    
    public var expression: Expression {
        return .uuid(self)
    }
    
}

extension Date: ValueExpressionType {
    
    public var expression: Expression {
        return .date(self)
    }
    
}

extension URL: ValueExpressionType {
    
    public var expression: Expression {
        return .url(self)
    }
    
}

#if canImport(MapKit) && !os(watchOS)
extension MKCircle: GeoValueExpressionType {
    
    public var expression: Expression {
        return .circle(self)
    }
    
}

extension MKPolygon: GeoValueExpressionType {
    
    public var expression: Expression {
        return .polygon(self)
    }
    
}
#endif

// MARK: - Optional Expression

extension Optional where Wrapped: ExpressionType {
    
    public var expression: Expression {
        if let value = self {
            return value.expression
        }
        return .null
    }
    
}

// MARK: - Optional PredicateKind

extension Optional where Wrapped == BooleanExpression {
    
    var predicateKind: PredicateKind? {
        switch self {
        case .some(let wrapped):
            return .booleanExpression(wrapped)
        default:
            return nil
        }
    }
    
}

extension Optional where Wrapped == NSPredicate {
    
    var predicateKind: PredicateKind? {
        switch self {
        case .some(let wrapped):
            return .predicate(wrapped)
        default:
            return nil
        }
    }
    
}
