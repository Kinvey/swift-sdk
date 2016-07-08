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

internal class RealmCache<T: Persistable where T: NSObject>: Cache<T> {
    
    let realm: Realm
    let objectSchema: ObjectSchema
    let propertyNames: [String]
    let executor: Executor
    
    lazy var entityType = T.self as! Entity.Type
    
    required init(persistenceId: String, filePath: String? = nil, encryptionKey: NSData? = nil, schemaVersion: UInt64) {
        if !(T.self is Entity.Type) {
            preconditionFailure("\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let filePath = filePath {
            configuration.fileURL = NSURL(fileURLWithPath: filePath)
        }
        configuration.encryptionKey = encryptionKey
        configuration.schemaVersion = schemaVersion
        
        do {
            realm = try Realm(configuration: configuration)
        } catch {
            configuration.deleteRealmIfMigrationNeeded = true
            realm = try! Realm(configuration: configuration)
        }
        
        let className = NSStringFromClass(T.self).componentsSeparatedByString(".").last!
        objectSchema = realm.schema[className]!
        propertyNames = objectSchema.properties.map { return $0.name }
        executor = Executor()
        print("\(realm.configuration.fileURL!.path!)")
        super.init(persistenceId: persistenceId)
    }
    
    private func results(query: Query) -> RealmSwift.Results<Entity> {
        var realmResults = self.realm.objects(self.entityType)
        if let predicate = query.predicate {
            realmResults = realmResults.filter(predicate)
        }
        if let sortDescriptors = query.sortDescriptors {
            for sortDescriptor in sortDescriptors {
                realmResults = realmResults.sorted(sortDescriptor.key!, ascending: sortDescriptor.ascending)
            }
        }
        
        if let ttl = ttl, let kmdKey = T.metadataProperty() {
            realmResults = realmResults.filter("\(kmdKey).lrt >= %@", NSDate().dateByAddingTimeInterval(-ttl))
        }
        
        return realmResults
    }
    
    private func newInstance<P: Persistable>(type: P.Type) -> P {
        return type.init()
    }
    
    override func detach(entity: T) -> T {
        let json = entity.dictionaryWithValuesForKeys(propertyNames)
        let obj = newInstance(T.self)
        obj.setValuesForKeysWithDictionary(json)
        return obj
    }
    
    override func detach(array: [T]) -> [T] {
        var results = [T]()
        for entity in array {
            results.append(detach(entity))
        }
        return results
    }
    
    override func saveEntity(entity: T) {
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.create((entity.dynamicType as! Entity.Type), value: entity, update: true)
            }
        }
    }
    
    override func saveEntities(entities: [T]) {
        executor.executeAndWait {
            try! self.realm.write {
                for entity in entities {
                    self.realm.create((entity.dynamicType as! Entity.Type), value: entity, update: true)
                }
            }
        }
    }
    
    override func findEntity(objectId: String) -> T? {
        var result: T?
        executor.executeAndWait {
            result = self.realm.objectForPrimaryKey(self.entityType, key: objectId) as? T
            if result != nil {
                result = self.detach(result!)
            }
        }
        return result
    }
    
    override func findEntityByQuery(query: Query) -> [T] {
        var results = [T]()
        executor.executeAndWait {
            results = (RealmResultsArray<Entity>(self.results(query)) as NSArray) as! [T]
            results = self.detach(results)
        }
        return results
    }
    
    override func findIdsLmtsByQuery(query: Query) -> [String : String] {
        var results = [String : String]()
        executor.executeAndWait {
            for entity in self.results(query) {
                results[entity.entityId!] = entity.metadata!.lmt!
            }
        }
        return results
    }
    
    override func findAll() -> [T] {
        var results = [T]()
        executor.executeAndWait {
            results = (RealmResultsArray<Entity>(self.realm.objects(self.entityType)) as NSArray) as! [T]
            results = self.detach(results)
        }
        return results
    }
    
    override func count() -> UInt {
        var result = UInt(0)
        executor.executeAndWait {
            result = UInt(self.realm.objects(self.entityType).count)
        }
        return result
    }
    
    override func removeEntity(entity: T) -> Bool {
        var result = false
        executor.executeAndWait {
            try! self.realm.write {
                let entity = self.realm.objectForPrimaryKey((entity.dynamicType as! Entity.Type), key: entity.entityId)!
                self.realm.delete(entity)
            }
            result = true
        }
        return result
    }
    
    override func removeEntities(entities: [T]) -> Bool {
        var result = false
        executor.executeAndWait {
            try! self.realm.write {
                for entity in entities {
                    let entity = self.realm.objectForPrimaryKey((entity.dynamicType as! Entity.Type), key: entity.entityId)
                    if let entity = entity {
                        self.realm.delete(entity)
                        result = true
                    }
                }
            }
        }
        return result
    }
    
    override func removeEntitiesByQuery(query: Query) -> UInt {
        var result = UInt(0)
        executor.executeAndWait {
            try! self.realm.write {
                let results = self.results(query)
                result = UInt(results.count)
                self.realm.delete(results)
            }
        }
        return result
    }
    
    override func removeAllEntities() {
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.delete(self.realm.objects(self.entityType))
            }
        }
    }
    
}

internal class RealmPendingOperation: Object, PendingOperationType {
    
    dynamic var requestId: String
    dynamic var date: NSDate
    
    dynamic var collectionName: String
    dynamic var objectId: String?
    
    dynamic var method: String
    dynamic var url: String
    dynamic var headers: NSData
    dynamic var body: NSData?
    
    init(request: NSURLRequest, collectionName: String, objectId: String?) {
        date = NSDate()
        requestId = request.valueForHTTPHeaderField(RequestIdHeaderKey)!
        self.collectionName = collectionName
        self.objectId = objectId
        method = request.HTTPMethod ?? "GET"
        url = request.URL!.absoluteString
        headers = try! NSJSONSerialization.dataWithJSONObject(request.allHTTPHeaderFields!, options: [])
        body = request.HTTPBody
        super.init()
    }
    
    required init() {
        date = NSDate()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = NSData()
        super.init()
    }
    
    required init(value: AnyObject, schema: RLMSchema) {
        date = NSDate()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = NSData()
        super.init(value: value, schema: schema)
    }
    
    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        date = NSDate()
        requestId = ""
        collectionName = ""
        method = ""
        url = ""
        headers = NSData()
        super.init(realm: realm, schema: schema)
    }
    
    func buildRequest() -> NSMutableURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!)
        request.HTTPMethod = method
        request.allHTTPHeaderFields = try? NSJSONSerialization.JSONObjectWithData(headers, options: []) as! [String : String]
        if let body = body {
            request.HTTPBody = body
        }
        return request
    }
    
    override class func primaryKey() -> String? {
        return "requestId"
    }
    
}
