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

internal class RealmCache<T: Persistable>: Cache<T> where T: NSObject {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let executor: Executor
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String, fileURL: URL? = nil, encryptionKey: Data? = nil, schemaVersion: UInt64) {
        if !(T.self is Entity.Type) {
            let message = "\(T.self) needs to be a Entity"
            log.severe(message)
            fatalError(message)
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
        
        let className = NSStringFromClass(T.self).components(separatedBy: ".").last!
        objectSchema = realm.schema[className]!
        propertyNames = objectSchema.properties.map {
            return $0.name
        }
        executor = Executor()
        super.init(persistenceId: persistenceId)
        log.debug("Cache File: \(self.realm.configuration.fileURL!.path)")
    }
    
    fileprivate func results(_ query: Query) -> RealmSwift.Results<Entity> {
        log.verbose("Fetching by query: \(query)")
        var realmResults = self.realm.objects(self.entityType)
        if let predicate = query.predicate {
            realmResults = realmResults.filter(predicate.realmPredicate)
        }
        if let sortDescriptors = query.sortDescriptors {
            for sortDescriptor in sortDescriptors {
                realmResults = realmResults.sorted(byKeyPath: sortDescriptor.key!, ascending: sortDescriptor.ascending)
            }
        }
        
        if let ttl = ttl, let kmdKey = T.metadataProperty() {
            realmResults = realmResults.filter("\(kmdKey).lrt >= %@", Date().addingTimeInterval(-ttl))
        }
        
        return realmResults
    }
    
    fileprivate func newInstance<P:Persistable>(_ type: P.Type) -> P {
        return type.init()
    }

    fileprivate func detach(_ entity: Object, props: [String]) -> Object {
        log.verbose("Detaching object: \(entity)")
        
        var json:Dictionary<String, Any>
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
    
    override func detach(_ results: [T], query: Query?) -> [T] {
        log.verbose("Detaching \(results.count) object(s)")
        var detachedResults = [T]()
        let skip = query?.skip ?? 0
        let limit = query?.limit ?? results.count
        var arrayEnumerate: [T]
        if skip != 0 || limit != results.count {
            let begin = max(min(skip, results.count), 0)
            let end = max(min(skip + limit, results.count), 0)
            arrayEnumerate = Array<T>(results[begin ..< end])
        } else {
            arrayEnumerate = results
        }
        for entity in arrayEnumerate {
            if let entity = entity as? Object {
                detachedResults.append(detach(entity, props: self.propertyNames) as! T)
            }
        }
        return detachedResults
    }
    
    func detach(_ results: RealmSwift.Results<Entity>, query: Query?) -> [T] {
        var results: [T] = results.map { $0 as! T }
        if let predicate = query?.predicate {
            results = results.filter(predicate: predicate)
        }
        return detach(results, query: query)
    }
    
    override func saveEntity(_ entity: T) {
        log.verbose("Saving object: \(entity)")
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.create((type(of: entity) as! Entity.Type), value: entity, update: true)
            }
        }
    }
    
    override func saveEntities(_ entities: [T]) {
        log.verbose("Saving \(entities.count) object(s)")
        executor.executeAndWait {
            try! self.realm.write {
                for entity in entities {
                    self.realm.create((type(of: entity) as! Entity.Type), value: entity, update: true)
                }
            }
        }
    }
    
    override func findEntity(_ objectId: String) -> T? {
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
    
    override func findEntityByQuery(_ query: Query) -> [T] {
        log.verbose("Finding objects by query: \(query)")
        var results = [T]()
        executor.executeAndWait {
            results = self.detach(self.results(query), query: query)
        }
        return results
    }
    
    override func findIdsLmtsByQuery(_ query: Query) -> [String : String] {
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
    
    override func findAll() -> [T] {
        log.verbose("Finding All")
        var results = [T]()
        executor.executeAndWait {
            results = self.detach(self.realm.objects(self.entityType), query: nil)
        }
        return results
    }
    
    override func count(_ query: Query? = nil) -> Int {
        log.verbose("Counting by query: \(query)")
        var result = 0
        executor.executeAndWait {
            if let query = query {
                result = self.results(query).count
            } else {
                result = self.realm.objects(self.entityType).count
            }
        }
        return result
    }
    
    override func removeEntity(_ entity: T) -> Bool {
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
    
    override func removeEntities(_ entities: [T]) -> Bool {
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
    
    override func removeEntitiesByQuery(_ query: Query) -> Int {
        log.verbose("Removing objects by query: \(query)")
        var result = 0
        executor.executeAndWait {
            try! self.realm.write {
                let results = self.results(query)
                result = results.count
                self.realm.delete(results)
            }
        }
        return result
    }
    
    override func removeAllEntities() {
        log.verbose("Removing all objects")
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.delete(self.realm.objects(self.entityType))
            }
        }
    }
    
}

extension NSPredicate {
    
    fileprivate var realmPredicate: NSPredicate {
        if let predicate = self as? NSComparisonPredicate,
            let keyPathConstantTuple = predicate.keyPathConstantTuple,
            let constantValue = keyPathConstantTuple.constantValueExpression.constantValue,
            constantValue is MKCircle || constantValue is MKPolygon
        {
            // geolocation queries are not handled by Realm, so ignore for now to perform the filter later
            return NSPredicate(value: true)
        }
        return self
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

extension Array where Element: NSObject, Element: Persistable {
    
    fileprivate func filter(predicate: NSPredicate) -> [Array.Element] {
        if let predicate = predicate as? NSComparisonPredicate,
            let keyPathConstantTuple = predicate.keyPathConstantTuple,
            let constantValue = keyPathConstantTuple.constantValueExpression.constantValue,
            constantValue is MKCircle || constantValue is MKPolygon
        {
            if let circle = constantValue as? MKCircle {
                let center = CLLocation(latitude: circle.coordinate.latitude, longitude: circle.coordinate.longitude)
                return filter({ (item) -> Bool in
                    if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                        return CLLocation(geoPoint: geoPoint).distance(from: center) <= circle.radius
                    }
                    return false
                })
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
                return filter({ (item) -> Bool in
                    if let geoPoint = item[keyPathConstantTuple.keyPathExpression.keyPath] as? GeoPoint {
                        return path.contains(CGPoint(x: geoPoint.latitude, y: geoPoint.longitude))
                    }
                    return false
                })
            }
        }
        return self
    }
    
}

internal class RealmPendingOperation: Object, PendingOperationType {
    
    dynamic var requestId: String
    dynamic var date: Date
    
    dynamic var collectionName: String
    dynamic var objectId: String?
    
    dynamic var method: String
    dynamic var url: String
    dynamic var headers: Data
    dynamic var body: Data?
    
    init(request: URLRequest, collectionName: String, objectId: String?) {
        date = Date()
        requestId = request.value(forHTTPHeaderField: .requestId)!
        self.collectionName = collectionName
        self.objectId = objectId
        method = request.httpMethod ?? "GET"
        url = request.url!.absoluteString
        headers = try! JSONSerialization.data(withJSONObject: request.allHTTPHeaderFields!, options: [])
        body = request.httpBody
        super.init()
    }
    
    required init() {
        date = Date()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = Data()
        super.init()
    }
    
    required init(value: Any, schema: RLMSchema) {
        date = Date()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = Data()
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        date = Date()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = Data()
        super.init(realm: realm, schema: schema)
    }
    
    func buildRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.allHTTPHeaderFields = try? JSONSerialization.jsonObject(with: headers, options: []) as! [String : String]
        if let body = body {
            request.httpBody = body
        }
        return request
    }
    
    override class func primaryKey() -> String? {
        return "requestId"
    }
    
}
