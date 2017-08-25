//
//  RealmCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import MapKit

fileprivate let typeStringValue = StringValue.self.className()
fileprivate let typeIntValue = IntValue.self.className()
fileprivate let typeFloatValue = FloatValue.self.className()
fileprivate let typeDoubleValue = DoubleValue.self.className()
fileprivate let typeBoolValue = BoolValue.self.className()
fileprivate let typesNeedsTranslation = [
    typeStringValue,
    typeIntValue,
    typeFloatValue,
    typeDoubleValue,
    typeBoolValue
]

#if !os(watchOS)
    fileprivate func tupleMKShape(predicate: NSPredicate) -> (NSComparisonPredicate, (keyPathExpression: NSExpression, constantValueExpression: NSExpression), Any)? {
        if let predicate = predicate as? NSComparisonPredicate,
            let keyPathConstantTuple = predicate.keyPathConstantTuple,
            let constantValue = keyPathConstantTuple.constantValueExpression.constantValue,
            constantValue is MKCircle || constantValue is MKPolygon
        {
            return (predicate, keyPathConstantTuple, constantValue)
        }
        return nil
    }
#endif

internal class RealmCache<T: Persistable>: Cache<T>, CacheType where T: NSObject {
    
    typealias `Type` = T
    
    let configuration: Realm.Configuration
    let realm: Realm
    let objectSchema: ObjectSchema
    let properties: [String : Property]
    let propertyNames: [String]
    let propertyTypes: [PropertyType]
    let propertyObjectClassNames: [String?]
    let needsTranslation: Bool
    let executor: Executor
    
    lazy var entityType = T.self as! Entity.Type
    
    var dynamic: DynamicCacheType? {
        return self
    }
    
    var newRealm: Realm {
        return try! Realm(configuration: configuration)
    }
    
    required init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) {
        if !(T.self is Entity.Type) {
            fatalError("\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let fileURL = fileURL {
            configuration.fileURL = fileURL
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion
        
        do {
            realm = try Realm(configuration: configuration)
        } catch {
            configuration.deleteRealmIfMigrationNeeded = true
            realm = try! Realm(configuration: configuration)
        }
        self.configuration = configuration
        
        let className = NSStringFromClass(T.self).components(separatedBy: ".").last!
        objectSchema = realm.schema[className]!
        
        var properties = [String : Property]()
        var propertyNames = [String]()
        var propertyTypes = [PropertyType]()
        var propertyObjectClassNames = [String?]()
        for property in objectSchema.properties {
            properties[property.name] = property
            propertyNames.append(property.name)
            propertyTypes.append(property.type)
            propertyObjectClassNames.append(property.objectClassName)
        }
        self.properties = properties
        self.propertyNames = propertyNames
        self.propertyTypes = propertyTypes
        self.propertyObjectClassNames = propertyObjectClassNames
        needsTranslation = !propertyObjectClassNames.filter {
            if let className = $0 {
                return typesNeedsTranslation.contains(className)
            }
            return false
        }.isEmpty
        
        executor = Executor()
        super.init(persistenceId: persistenceId)
        log.debug("Cache File: \(self.realm.configuration.fileURL!.path)")
    }
    
    func translate(predicate: NSPredicate) -> NSPredicate {
        #if !os(watchOS)
            if let _ = tupleMKShape(predicate: predicate)
            {
                return NSPredicate(value: true)
            }
        #endif
        
        if let predicate = predicate as? NSComparisonPredicate {
            let leftExpressionNeedsTranslation = needsTranslation(expression: predicate.leftExpression)
            let rightExpressionNeedsTranslation = needsTranslation(expression: predicate.rightExpression)
            if (leftExpressionNeedsTranslation || rightExpressionNeedsTranslation) {
                if predicate.predicateOperatorType == .contains, let keyPathValuePairExpression = keyPathValuePairExpression(predicate: predicate) {
                    return NSPredicate(format: "SUBQUERY(\(keyPathValuePairExpression.keyPathExpression.keyPath), $item, $item.value == %@).@count > 0", keyPathValuePairExpression.valueExpression.constantValue as! CVarArg)
                } else {
                    return NSComparisonPredicate(
                        leftExpression: translate(expression: predicate.leftExpression),
                        rightExpression: translate(expression: predicate.rightExpression),
                        modifier: predicate.comparisonPredicateModifier,
                        type: predicate.predicateOperatorType,
                        options: predicate.options
                    )
                }
            }
        }
        
        return predicate
    }
    
    func needsTranslation(expression: NSExpression) -> Bool {
        switch expression.expressionType {
        case .keyPath:
            let keyPath = expression.keyPath
            if keyPath.contains(".") {
            } else {
                if let idx = propertyNames.index(of: keyPath),
                    let className = propertyObjectClassNames[idx],
                    typesNeedsTranslation.contains(className)
                {
                    return true
                }
            }
            return false
        case .function:
            if needsTranslation(expression: expression.operand) {
                return true
            } else if let arguments = expression.arguments {
                for expression in arguments {
                    if needsTranslation(expression: expression) {
                        return true
                    }
                }
            }
            return false
        case .subquery:
            if let expression = expression.collection as? NSExpression {
                return needsTranslation(expression: expression)
            }
            return false
        default:
            return false
        }
    }
    
    func keyPathValuePairExpression(predicate: NSComparisonPredicate) -> (keyPathExpression: NSExpression, valueExpression: NSExpression)? {
        switch predicate.leftExpression.expressionType {
        case .keyPath:
            switch predicate.rightExpression.expressionType {
            case .constantValue:
                return (keyPathExpression: predicate.leftExpression, valueExpression: predicate.rightExpression)
            default:
                return nil
            }
        case .constantValue:
            switch predicate.rightExpression.expressionType {
            case .keyPath:
                return (keyPathExpression: predicate.rightExpression, valueExpression: predicate.leftExpression)
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
    func variableValuePairExpression(predicate: NSComparisonPredicate) -> (variableExpression: NSExpression, expression: NSExpression)? {
        switch predicate.leftExpression.expressionType {
        case .variable:
            return (variableExpression: predicate.leftExpression, expression: predicate.rightExpression)
        default:
            switch predicate.rightExpression.expressionType {
            case .variable:
                return (variableExpression: predicate.rightExpression, expression: predicate.leftExpression)
            default:
                return nil
            }
        }
    }
    
    func translate(expression: NSExpression) -> NSExpression {
        switch expression.expressionType {
        case .keyPath:
            var keyPath = expression.keyPath
            if keyPath.contains(".") {
            } else {
                if let idx = propertyNames.index(of: keyPath),
                    let className = propertyObjectClassNames[idx],
                    typesNeedsTranslation.contains(className)
                {
                    keyPath += ".value"
                }
            }
            return NSExpression(forKeyPath: keyPath)
        case .function:
            if expression.operand.expressionType == .subquery,
                let suffix = expression.arguments?.first?.description
            {
                let subquery = translate(expression: expression.operand)
                return NSExpression(format: "\(subquery).\(suffix)")
            } else {
                switch expression.function {
                case "objectFrom:withIndex:":
                    if let keyPath = expression.arguments?.first?.description,
                        let idx = expression.arguments?.last?.description,
                        idx != "SIZE"
                    {
                        return NSExpression(format: "\(keyPath)[\(idx)].value")
                    }
                    return expression
                default:
                    return expression
                }
            }
        case .subquery:
            if let collectionExpression = expression.collection as? NSExpression,
                let subqueryPredicate = expression.predicate as? NSComparisonPredicate,
                let variableValuePairExpression = variableValuePairExpression(predicate: subqueryPredicate)
            {
                let predicate = NSComparisonPredicate(
                    leftExpression: NSExpression(forVariable: "\(variableValuePairExpression.variableExpression.variable).value"),
                    rightExpression: variableValuePairExpression.expression,
                    modifier: subqueryPredicate.comparisonPredicateModifier,
                    type: subqueryPredicate.predicateOperatorType,
                    options: subqueryPredicate.options
                )
                return NSExpression(
                    forSubquery: collectionExpression,
                    usingIteratorVariable: variableValuePairExpression.variableExpression.variable,
                    predicate: predicate
                )
            }
            return expression
        default:
            return expression
        }
    }
    
    fileprivate func results(_ query: Query) -> AnyRandomAccessCollection<Entity> {
        log.verbose("Fetching by query: \(query)")
        
        var realmResults = self.realm.objects(self.entityType)
        if let predicate = query.predicate {
            if let exception = tryBlock({
                realmResults = realmResults.filter(self.translate(predicate: predicate))
            }), let reason = exception.reason
            {
                switch exception.name.rawValue {
                case "Invalid property name":
                    return AnyRandomAccessCollection([])
                default:
                    fatalError(reason)
                }
            }
        }
        if let sortDescriptors = query.sortDescriptors {
            for sortDescriptor in sortDescriptors {
                realmResults = realmResults.sorted(byKeyPath: sortDescriptor.key!, ascending: sortDescriptor.ascending)
            }
        }
        
        if let ttl = ttl, let kmdKey = T.metadataProperty() {
            realmResults = realmResults.filter("\(kmdKey).lrt >= %@", Date().addingTimeInterval(-ttl))
        }
        
        return AnyRandomAccessCollection(realmResults)
    }

    fileprivate func detach(_ entity: Object, props: [String]) -> Object {
        log.verbose("Detaching object: \(entity)")
        
        var json: Dictionary<String, Any>
        let obj = type(of:entity).init()
        
        json = entity.dictionaryWithValues(forKeys: props)
        
        for property in json.keys {
            let value = json[property]
                
            if let value = value as? Object {
                
                let nestedClassName = StringFromClass(cls: type(of:value)).components(separatedBy: ".").last!
                let nestedObjectSchema = realm.schema[nestedClassName]
                let nestedProperties = nestedObjectSchema?.properties.map { $0.name }
                    
                json[property] = self.detach(value, props: nestedProperties!)
            }
        }
            
        obj.setValuesForKeys(json)
            
        return obj

    }
    
    func detach(entities: AnyRandomAccessCollection<T>, query: Query?) -> AnyRandomAccessCollection<T> {
        log.verbose("Detaching \(entities.count) object(s)")
        let skip = query?.skip ?? 0
        let limit = query?.limit ?? Int(entities.count)
        var arrayEnumerate: AnyRandomAccessCollection<T>
        if skip != 0 || limit != Int(entities.count) {
            let begin = max(min(skip, Int(entities.count)), 0)
            let end = max(min(skip + limit, Int(entities.count)), 0)
            arrayEnumerate = AnyRandomAccessCollection(Array(entities)[begin ..< end])
        } else {
            arrayEnumerate = AnyRandomAccessCollection(entities)
        }
        let detachedResults = arrayEnumerate.lazy.map {
            self.detach($0 as! Object, props: self.propertyNames) as! T
        }
        return AnyRandomAccessCollection(detachedResults)
    }
    
    func detach(_ results: AnyRandomAccessCollection<Entity>, query: Query?) -> AnyRandomAccessCollection<T> {
        var results = AnyRandomAccessCollection(results.lazy.map {
            $0 as! T
        })
        if let predicate = query?.predicate {
            results = results.filter(predicate: predicate)
        }
        return detach(entities: AnyRandomAccessCollection(results), query: query)
    }
    
    func save(entity: T) {
        log.verbose("Saving object: \(entity)")
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.create((type(of: entity) as! Entity.Type), value: entity, update: true)
            }
        }
    }
    
    func save(entities: AnyRandomAccessCollection<Type>) {
        let startTime = CFAbsoluteTimeGetCurrent()
        log.verbose("Saving \(entities.count) object(s)")
        executor.executeAndWait {
            let realm = self.realm
            let entityType = self.entityType
            try! realm.write {
                for entity in entities {
                    realm.create(entityType, value: entity, update: true)
                }
            }
        }
        log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
    }
    
    func find(byId objectId: String) -> T? {
        log.verbose("Finding object by ID: \(objectId)")
        var result: T?
        executor.executeAndWait {
            result = self.realm.object(ofType: self.entityType, forPrimaryKey: objectId) as? T
            if result != nil {
                if let resultObj = result as? Object {
                    result = self.detach(resultObj, props: self.propertyNames) as? T
                }
            }
        }
        return result
    }
    
    func find(byQuery query: Query) -> AnyRandomAccessCollection<T> {
        log.verbose("Finding objects by query: \(query)")
        var results = AnyRandomAccessCollection<T>([])
        executor.executeAndWait {
            let _results = self.results(query)
            results = self.detach(_results, query: query)
        }
        return results
    }
    
    func findIdsLmts(byQuery query: Query) -> [String : String] {
        log.verbose("Finding ids and lmts by query: \(query)")
        var results = [String : String]()
        executor.executeAndWait {
            for entity in self.results(Query(predicate: query.predicate)) {
                if let entityId = entity.entityId, let lmt = entity.metadata?.lmt {
                    results[entityId] = lmt
                }
            }
        }
        return results
    }
    
    func count(query: Query? = nil) -> Int {
        log.verbose("Counting by query: \(String(describing: query))")
        var result = 0
        executor.executeAndWait {
            if let query = query {
                result = Int(self.results(query).count)
            } else {
                result = self.realm.objects(self.entityType).count
            }
        }
        return result
    }
    
    func remove(entity: T) -> Bool {
        log.verbose("Removing object: \(entity)")
        var result = false
        if let entityId = entity.entityId {
            executor.executeAndWait {
                var found = false
                try! self.realm.write {
                    if let entity = self.realm.object(ofType: (type(of: entity) as! Entity.Type), forPrimaryKey: entityId) {
                        self.realm.delete(entity)
                        found = true
                    }
                }
                result = found
            }
        }
        return result
    }
    
    func remove(entities: AnyRandomAccessCollection<Type>) -> Bool {
        log.verbose("Removing objects: \(entities)")
        var result = false
        executor.executeAndWait {
            try! self.realm.write {
                for entity in entities {
                    let entity = self.realm.object(ofType: type(of: entity) as! Entity.Type, forPrimaryKey: entity.entityId!)
                    if let entity = entity {
                        self.realm.delete(entity)
                        result = true
                    }
                }
            }
        }
        return result
    }
    
    func remove(byQuery query: Query) -> Int {
        log.verbose("Removing objects by query: \(query)")
        var result = 0
        executor.executeAndWait {
            try! self.realm.write {
                let results = self.results(query)
                result = Int(results.count)
                self.realm.delete(results)
            }
        }
        return result
    }
    
    func clear(query: Query? = nil) {
        log.verbose("Clearing cache")
        executor.executeAndWait {
            try! self.realm.write {
                if let query = query {
                    var results = self.realm.objects(self.entityType)
                    if let predicate = query.predicate {
                        results = results.filter(predicate)
                    }
                    let ids: [String] = results.map { $0.entityId! }
                    
                    var pendingOperations = self.realm.objects(RealmPendingOperation.self)
                    pendingOperations = pendingOperations.filter("collectionName == %@ AND objectId IN %@", self.collectionName, ids)
                    
                    self.realm.delete(results)
                    self.realm.delete(pendingOperations)
                } else {
                    self.realm.deleteAll()
                }
            }
        }
    }
    
}

extension RealmCache: DynamicCacheType {
    
    func save(entities: AnyRandomAccessCollection<JsonDictionary>) {
        let startTime = CFAbsoluteTimeGetCurrent()
        log.verbose("Saving \(entities.count) object(s)")
        let realm = self.newRealm
        let entityType = self.entityType.className()
        let propertyMapping = T.propertyMapping()
        try! realm.write {
            for entity in entities {
                var translatedEntity = JsonDictionary()
                for (translatedKey, (key, transform)) in propertyMapping {
                    if let transform = transform,
                        let value = transform.transformFromJSON(entity[key]) as? NSObject,
                        let property = properties[translatedKey],
                        property.type != .array,
                        let objectClassName = property.objectClassName,
                        let schema = realm.schema[objectClassName]
                    {
                        translatedEntity[translatedKey] = value.dictionaryWithValues(forKeys: schema.properties.map { $0.name })
                    } else if needsTranslation,
                        let array = entity[key] as? [Any],
                        let property = properties[translatedKey],
                        let objectClassName = property.objectClassName,
                        typesNeedsTranslation.contains(objectClassName)
                    {
                        translatedEntity[translatedKey] = array.map {
                            return ["value" : $0]
                        }
                    } else {
                        translatedEntity[translatedKey] = entity[key]
                    }
                }
                realm.dynamicCreate(entityType, value: translatedEntity, update: true)
            }
        }
        log.debug("Time elapsed: \(CFAbsoluteTimeGetCurrent() - startTime) s")
    }
    
}

extension NSComparisonPredicate {
    
    var keyPathConstantTuple: (keyPathExpression: NSExpression, constantValueExpression: NSExpression)? {
        switch leftExpression.expressionType {
        case .keyPath:
            switch rightExpression.expressionType {
            case .constantValue:
                return (keyPathExpression: leftExpression, constantValueExpression: rightExpression)
            default:
                return nil
            }
        case .constantValue:
            switch rightExpression.expressionType {
            case .keyPath:
                return (keyPathExpression: rightExpression, constantValueExpression: leftExpression)
            default:
                return nil
            }
        default:
            return nil
        }
    }
    
}

extension AnyRandomAccessCollection where Element: NSObject, Element: Persistable {
    
    fileprivate func filter(predicate: NSPredicate) -> AnyRandomAccessCollection<Iterator.Element> {
        #if !os(watchOS)
            if let (_, keyPathConstantTuple, constantValue) = tupleMKShape(predicate: predicate)
            {
                if let circle = constantValue as? MKCircle {
                    let center = CLLocation(latitude: circle.coordinate.latitude, longitude: circle.coordinate.longitude)
                    return AnyRandomAccessCollection(filter({ (item) -> Bool in
                        if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                            return CLLocation(geoPoint: geoPoint).distance(from: center) <= circle.radius
                        }
                        return false
                    }))
                } else if let polygon = constantValue as? MKPolygon {
                    let pointCount = polygon.pointCount
                    var coordinates = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: polygon.pointCount)
                    polygon.getCoordinates(&coordinates, range: NSMakeRange(0, pointCount))
                    if let first = coordinates.first, let last = coordinates.last, first == last {
                        coordinates.removeLast()
                    }
                    #if os(OSX)
                        let path = NSBezierPath()
                    #else
                        let path = UIBezierPath()
                    #endif
                    for (i, coordinate) in coordinates.enumerated() {
                        let point = CGPoint(x: coordinate.latitude, y: coordinate.longitude)
                        switch i {
                        case 0:
                            path.move(to: point)
                        default:
                            #if os(OSX)
                                path.line(to: point)
                            #else
                                path.addLine(to: point)
                            #endif
                        }
                    }
                    path.close()
                    return AnyRandomAccessCollection(filter({ (item) -> Bool in
                        if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                            return path.contains(CGPoint(x: geoPoint.latitude, y: geoPoint.longitude))
                        }
                        return false
                    }))
                }
            }
        #endif
        return self
    }
    
}

internal class RealmPendingOperation: Object, PendingOperationType {
    
    dynamic var requestId: String = ""
    dynamic var date: Date = Date()
    
    dynamic var collectionName: String = ""
    dynamic var objectId: String?
    
    dynamic var method: String = ""
    dynamic var url: String = ""
    dynamic var headers: Data = Data()
    dynamic var body: Data?
    
    convenience init(request: URLRequest, collectionName: String, objectId: String?) {
        self.init()
        
        requestId = request.value(forHTTPHeaderField: KinveyHeaderField.requestId)!
        self.collectionName = collectionName
        self.objectId = objectId
        method = request.httpMethod ?? "GET"
        url = request.url!.absoluteString
        headers = try! JSONSerialization.data(withJSONObject: request.allHTTPHeaderFields!)
        body = request.httpBody
    }
    
    func buildRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.allHTTPHeaderFields = try? JSONSerialization.jsonObject(with: headers) as! [String : String]
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    override class func primaryKey() -> String? {
        return "requestId"
    }
    
}

class RealmPendingOperationThreadSafeReference: PendingOperationType {
    
    let realmConfig: Realm.Configuration
    let reference: ThreadSafeReference<RealmPendingOperation>
    
    init(_ realmPendingOperation: RealmPendingOperation) {
        realmConfig = realmPendingOperation.realm!.configuration
        reference = ThreadSafeReference(to: realmPendingOperation)
    }
    
    lazy var realmPendingOperation: RealmPendingOperation = { [unowned self] in
        let realm = try! Realm(configuration: self.realmConfig)
        return realm.resolve(self.reference)!
    }()
    
    var collectionName: String {
        return realmPendingOperation.collectionName
    }
    
    var objectId: String? {
        return realmPendingOperation.objectId
    }
    
    func buildRequest() -> URLRequest {
        return realmPendingOperation.buildRequest()
    }
    
}
