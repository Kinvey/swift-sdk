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

fileprivate let typeStringValue = StringValue.self.className()
fileprivate let typeIntValue = IntValue.self.className()
fileprivate let typeFloatValue = FloatValue.self.className()
fileprivate let typeDoubleValue = DoubleValue.self.className()
fileprivate let typeBoolValue = BoolValue.self.className()
internal let typesNeedsTranslation = [
    typeStringValue,
    typeIntValue,
    typeFloatValue,
    typeDoubleValue,
    typeBoolValue
]

extension RealmSwift.NotificationToken: NotificationToken {
}

internal class RealmCache<T: Persistable>: Cache<T>, CacheType, RealmCascadeDeletable where T: NSObject {
    
    typealias `Type` = T
    
    let configuration: Realm.Configuration
    let objectSchema: ObjectSchema
    let properties: [String : Property]
    let propertyNames: [String]
    let propertyTypes: [PropertyType]
    let propertyObjectClassNames: [String?]
    let needsTranslation: Bool
    
    lazy var entityType = T.self as! Entity.Type
    lazy var entityTypeClassName = entityType.className()
    lazy var entityTypeCollectionName = try! entityType.collectionName()
    
    var dynamic: DynamicCacheType? {
        return self
    }
    
    var newRealm: Realm {
        let realm = try! Realm(configuration: configuration)
        realm.refresh()
        return realm
    }
    
    required init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) throws {
        if !(T.self is Entity.Type) {
            throw Error.invalidOperation(description: "\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let fileURL = fileURL {
            configuration.fileURL = fileURL
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion

        let realm: Realm
        do {
            realm = try Realm(configuration: configuration)
        } catch {
            configuration.deleteRealmIfMigrationNeeded = true
            realm = try Realm(configuration: configuration)
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
        
        super.init(persistenceId: persistenceId)
        log.debug("Cache File: \(newRealm.configuration.fileURL!.path)")
    }
    
    func translate(predicate: NSPredicate) -> NSPredicate {
        #if !os(watchOS)
            if let _ = tupleMKShape(predicate: predicate)
            {
                return NSPredicate(value: true)
            }
        #endif
        
        if let predicate = predicate as? NSComparisonPredicate {
            if needsTranslation(expression: predicate.leftExpression) ||
                needsTranslation(expression: predicate.rightExpression)
            {
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
            if T.self is Codable.Type {
                return true
            }
            let keyPath = expression.keyPath
            if !keyPath.contains(".") {
                if let idx = propertyNames.firstIndex(of: keyPath),
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
            var keyPath = T.self is Codable.Type ? (try! T.translate(property: expression.keyPath) ?? expression.keyPath) : expression.keyPath
            if !keyPath.contains(".") {
                if let idx = propertyNames.firstIndex(of: keyPath),
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
    
    fileprivate func realmResults(_ query: Query) -> Results<Entity>? {
        var realmResults = newRealm.objects(self.entityType)
        
        if let predicate = query.predicate {
            #if SWIFT_PACKAGE
            realmResults = realmResults.filter(self.translate(predicate: predicate))
            #else
            if let exception = tryBlock({
                realmResults = realmResults.filter(self.translate(predicate: predicate))
            }), let reason = exception.reason
            {
                switch exception.name.rawValue {
                case "Invalid property name":
                    return nil
                default:
                    fatalError(reason)
                }
            }
            #endif
        }
        
        if let sortDescriptors = query.sortDescriptors {
            for sortDescriptor in sortDescriptors {
                realmResults = realmResults.sorted(byKeyPath: sortDescriptor.key!, ascending: sortDescriptor.ascending)
            }
        }
        
        if let ttl = ttl, let kmdKey = try? T.metadataProperty() {
            realmResults = realmResults.filter("\(kmdKey).lrt >= %@", Date().addingTimeInterval(-ttl))
        }
        
        return realmResults
    }
    
    fileprivate func results(_ query: Query) -> AnyRandomAccessCollection<Entity> {
        log.verbose("Fetching by query: \(query)")
        
        if let realmResults = self.realmResults(query) {
            return AnyRandomAccessCollection(realmResults)
        } else {
            return AnyRandomAccessCollection([])
        }
    }
    
    private func detach<T>(_ list: List<T>) -> List<T> where T: Object {
        let result = List<T>()
        for item in list {
            result.append(detach(item))
        }
        return result
    }
    
    private func detach(_ list: RLMSwiftCollectionBase) -> [Object] {
        var result = [Object]()
        let rlmCollection = list._rlmCollection
        result.reserveCapacity(Int(rlmCollection.count))
        for i in 0 ..< rlmCollection.count {
            let item = rlmCollection.object(at: i) as! Object
            let detached = detach(item)
            result.append(detached)
        }
        return result
    }

    fileprivate func detach<T>(_ entity: T) -> T where T: Object {
        log.verbose("Detaching object: \(entity)")
        
        var json: Dictionary<String, Any>
        let obj = type(of: entity).init()
        
        json = entity.dictionaryWithValues(forKeys: entity.objectSchema.properties.map { $0.name })
        
        json.keys.forEachAutoreleasepool { property in
            let value = json[property]
            
            switch value {
            case let value as Object:
                json[property] = self.detach(value)
            case var list as List<StringValue>:
                list = self.detach(list)
                json[property] = list
            case var list as List<IntValue>:
                list = self.detach(list)
                json[property] = list
            case var list as List<FloatValue>:
                list = self.detach(list)
                json[property] = list
            case var list as List<DoubleValue>:
                list = self.detach(list)
                json[property] = list
            case var list as List<BoolValue>:
                list = self.detach(list)
                json[property] = list
            case let list as RLMSwiftCollectionBase:
                json[property] = self.detach(list)
            default:
                break
            }
        }
            
        obj.setValuesForKeys(json)
        
        if let entityObj = obj as? Entity,
            entityObj.entityIdReference == nil,
            let entity = entity as? Entity,
            let realm = entity.realm
        {
            entityObj.realmConfiguration = realm.configuration
            entityObj.entityIdReference = (entity as NSObject & Persistable).entityId
        }
            
        return obj
    }
    
    func detach(entities: AnyRandomAccessCollection<T>, query: Query?) -> AnyRandomAccessCollection<T> {
        signpost(.begin, log: osLog, name: "Realm Detach Entities", "%d", entities.count)
        defer {
            signpost(.end, log: osLog, name: "Realm Detach Entities", "%d", entities.count)
        }
        let skip = query?.skip ?? 0
        let limit = query?.limit ?? Int(entities.count)
        var arrayEnumerate: AnyRandomAccessCollection<T>
        if skip != 0 || limit != Int(entities.count) {
            let begin = max(min(skip, Int(entities.count)), 0)
            let end = max(min(skip + limit, Int(entities.count)), 0)
            arrayEnumerate = AnyRandomAccessCollection(Array(entities)[begin ..< end])
        } else {
            arrayEnumerate = entities
        }
        let detachedResults = arrayEnumerate.lazy.map {
            self.detach($0 as! Object) as! T
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
        return detach(entities: results, query: query)
    }
    
    func save(entity: T) {
        log.verbose("Saving object: \(entity)")
        var newEntity: Entity!
        try! self.write { realm in
            if let entityId = entity.entityId, let oldEntity = realm.object(ofType: self.entityType, forPrimaryKey: entityId) {
                self.cascadeDelete(realm: realm, entityType: self.entityTypeClassName, entity: oldEntity, deleteItself: false)
            }
            newEntity = realm.create((type(of: entity) as! Entity.Type), value: entity, update: .all)
        }
        if let entity = entity as? Entity {
            entity.realmConfiguration = self.newRealm.configuration
            entity.entityIdReference = (newEntity as NSObject & Persistable).entityId
        }
    }
    
    func save<C>(entities: C, syncQuery: SyncQuery?) where C : Collection, C.Element == T {
        signpost(.begin, log: osLog, name: "Save Entities (Generics)")
        defer {
            signpost(.end, log: osLog, name: "Save Entities (Generics)")
        }
        log.debug("Saving \(entities.count) object(s)")
        let entityType = self.entityType
        var newEntities = [Entity]()
        newEntities.reserveCapacity(entities.count)
        try! self.write { realm in
            entities.forEachAutoreleasepool { entity in
                if let entityId = entity.entityId, let oldEntity = realm.object(ofType: entityType, forPrimaryKey: entityId) {
                    self.cascadeDelete(realm: realm, entityType: self.entityTypeClassName, entity: oldEntity, deleteItself: false)
                }
                let newEntity = realm.create(entityType, value: entity, update: .all)
                newEntities.append(newEntity)
            }
            self.saveQuery(syncQuery: syncQuery, realm: realm)
        }
        let realm = self.newRealm
        for (entity, newEntity) in zip(entities, newEntities) {
            if let entity = entity as? Entity {
                entity.realmConfiguration = realm.configuration
                entity.entityIdReference = (newEntity as NSObject & Persistable).entityId
            }
        }
    }
    
    func find(byId objectId: String) -> T? {
        log.verbose("Finding object by ID: \(objectId)")
        var result = self.newRealm.object(ofType: self.entityType, forPrimaryKey: objectId) as? T
        if result != nil {
            if let resultObj = result as? Object {
                result = self.detach(resultObj) as? T
            }
        }
        return result
    }
    
    func find(byQuery query: Query) -> AnyRandomAccessCollection<T> {
        log.verbose("Finding objects by query: \(query)")
        let _results = self.results(query)
        let results = self.detach(_results, query: query)
        return results
    }
    
    func findIdsLmts(byQuery query: Query) -> [String : String] {
        log.verbose("Finding ids and lmts by query: \(query)")
        var results = [String : String]()
        for entity in self.results(Query(predicate: query.predicate)) {
            if let entityId = entity.entityId, let lmt = entity.metadata?.lmt {
                results[entityId] = lmt
            }
        }
        return results
    }
    
    func count(query: Query? = nil) -> Int {
        log.verbose("Counting by query: \(String(describing: query))")
        var result = 0
        if let query = query {
            result = Int(self.results(query).count)
        } else {
            result = self.newRealm.objects(self.entityType).count
        }
        return result
    }
    
    func remove(entity: T) -> Bool {
        log.verbose("Removing object: \(entity)")
        var result = false
        if let entityId = entity.entityId {
            var found = false
            try! self.write { realm in
                let entityType = type(of: entity) as! Entity.Type
                let entityTypeClassName = entityType.className()
                if let entity = realm.object(ofType: entityType, forPrimaryKey: entityId) {
                    self.cascadeDelete(
                        realm: realm,
                        entityType: entityTypeClassName,
                        entity: entity
                    )
                    found = true
                }
            }
            result = found
        }
        return result
    }
    
    func remove(entities: AnyRandomAccessCollection<Type>) -> Bool {
        signpost(.begin, log: osLog, name: "Remove Entities", "%d", entities.count)
        defer {
            signpost(.end, log: osLog, name: "Remove Entities", "%d", entities.count)
        }
        var result = false
        try! self.write { realm in
            let entityType = self.entityType
            let entityTypeClassName = entityType.className()
            entities.forEachAutoreleasepool { entity in
                let entity = realm.object(ofType: entityType, forPrimaryKey: entity.entityId!)
                if let entity = entity {
                    self.cascadeDelete(
                        realm: realm,
                        entityType: entityTypeClassName,
                        entity: entity
                    )
                    result = true
                }
            }
        }
        return result
    }
    
    func remove(byQuery query: Query) -> Int {
        log.verbose("Removing objects by query: \(query)")
        var result = 0
        try! self.write { realm in
            let results = self.results(query)
            result = Int(results.count)
            realm.delete(results)
        }
        return result
    }
    
    func clear(query: Query? = nil) {
        clear(query: query, cascadeDelete: false)
    }
    
    func clear(query: Query? = nil, cascadeDelete: Bool = false) {
        log.verbose("Clearing cache")
        try! self.write { realm in
            if let query = query {
                var results = realm.objects(self.entityType)
                if let predicate = query.predicate {
                    results = results.filter(predicate)
                }
                let ids: [String] = results.map { $0.entityId! }
                
                let pendingOperations = realm.objects(RealmPendingOperation.self).filter("collectionName == %@ AND objectId IN %@", self.collectionName, ids)
                let syncedQueries = realm.objects(_QueryCache.self).filter("collectionName == %@", self.collectionName)
                
                if cascadeDelete {
                    for entity in results {
                        self.cascadeDelete(realm: realm, entityType: self.entityTypeClassName, entity: entity, deleteItself: true)
                    }
                } else {
                    realm.delete(results)
                }
                realm.delete(pendingOperations)
                realm.delete(syncedQueries)
            } else {
                realm.deleteAll()
            }
        }
    }
    
    func clear(syncQueries: [Query]?) {
        try! self.write { realm in
            var syncedQueries = realm.objects(_QueryCache.self).filter("collectionName == %@", self.collectionName)
            if let syncQueries = syncQueries {
                syncedQueries = syncedQueries.filter("query IN %@", syncQueries.compactMap({ $0.predicate }))
            }
            realm.delete(syncedQueries)
        }
    }
    
    internal func lastSync(query: Query, realm: Realm) -> Results<_QueryCache>? {
        realm.refresh()
        var results = realm.objects(_QueryCache.self)
        guard results.count > 0 else {
            return nil
        }
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "collectionName == %@", self.collectionName),
            (query.predicate?.asString).map({ NSPredicate(format: "query == %@", $0) }) ?? NSPredicate(format: "query == nil"),
            query.fieldsAsString.map({ NSPredicate(format: "fields == %@", $0) }) ?? NSPredicate(format: "fields == nil")
        ])
        results = results.filter(predicate)
        return results
    }
    
    func lastSync(query: Query) -> Date? {
        log.verbose("Retriving last sync date")
        return self.lastSync(query: query, realm: self.newRealm)?.first?.lastSync
    }
    
    func invalidateLastSync(query: Query) -> Date? {
        log.verbose("Invalidating last sync date")
        var lastSync: Date? = nil
        try! self.write { realm in
            guard let syncedQueries = self.lastSync(query: query, realm: realm), let firstSyncQuery = syncedQueries.first else {
                return
            }
            lastSync = firstSyncQuery.lastSync
            realm.delete(syncedQueries)
        }
        return lastSync
    }
    
    func observe(_ query: Query? = nil, completionHandler: @escaping (CollectionChange<AnyRandomAccessCollection<T>>) -> Void) -> AnyNotificationToken {
        var notificationToken: RealmSwift.NotificationToken!
        let query = query ?? Query()
        if let results = self.realmResults(query) {
            notificationToken = results.observe {
                switch $0 {
                case .initial(let realmResults):
                    let results = self.detach(AnyRandomAccessCollection(realmResults), query: query)
                    completionHandler(.initial(results))
                case .update(let realmResults, let deletions, let insertions, let modifications):
                    let results = self.detach(AnyRandomAccessCollection(realmResults), query: query)
                    completionHandler(.update(results, deletions: deletions, insertions: insertions, modifications: modifications))
                case .error(let error):
                    completionHandler(.error(error))
                }
            }
        }
        return AnyNotificationToken(notificationToken)
    }
    
    public func write(_ block: @escaping (() throws -> Swift.Void)) throws {
        var _error: Swift.Error? = nil
        do {
            try self.newRealm.write {
                try block()
            }
        } catch {
            _error = error
        }
        if let error = _error {
            throw error
        }
    }
    
    public func beginWrite() {
        self.newRealm.beginWrite()
    }
    
    public func commitWrite(withoutNotifying tokens: [NotificationToken]) throws {
        var _error: Swift.Error? = nil
        do {
            try self.newRealm.commitWrite(withoutNotifying: tokens.compactMap({
                $0 as? RealmSwift.NotificationToken ?? ($0 as? AnyNotificationToken)?.notificationToken as? RealmSwift.NotificationToken
            }))
        } catch {
            _error = error
        }
        if let error = _error {
            throw error
        }
    }
    
    public func cancelWrite() {
        self.newRealm.cancelWrite()
    }
    
    internal func write(_ block: @escaping (Realm) throws -> Void) throws {
        if newRealm.isInWriteTransaction {
            var _error: Swift.Error? = nil
            do {
                try block(self.newRealm)
            } catch {
                _error = error
            }
            if let error = _error {
                throw error
            }
        } else {
            let realm = self.newRealm
            try! realm.write {
                try block(realm)
            }
        }
    }
    
}
