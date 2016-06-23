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
    
    required init(persistenceId: String, filePath: String? = nil, encryptionKey: NSData? = nil) {
        if !(T.self is Entity.Type) {
            preconditionFailure("\(T.self) needs to be a Entity")
        }
        var configuration = Realm.Configuration()
        if let filePath = filePath {
            configuration.fileURL = NSURL(fileURLWithPath: filePath)
        }
        configuration.encryptionKey = encryptionKey
        realm = try! Realm(configuration: configuration)
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
        
        if self.ttl > 0, let kmdKey = T.kinveyMetadataPropertyName() {
            realmResults = realmResults.filter("\(kmdKey).lrt >= %@", NSDate().dateByAddingTimeInterval(-self.ttl))
        }
        
        return realmResults
    }
    
    override func detach(entity: T) -> T {
        let json = entity.dictionaryWithValuesForKeys(propertyNames)
        let obj = T()
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
                self.realm.add((entity as! Entity), update: true)
            }
        }
    }
    
    override func saveEntities(entities: [T]) {
        executor.executeAndWait {
            try! self.realm.write {
                for entity in entities {
                    self.realm.add((entity as! Entity), update: true)
                }
            }
        }
    }
    
    override func findEntity(objectId: String) -> T? {
        var result: T?
        executor.executeAndWait {
            result = self.realm.objectForPrimaryKey(self.entityType, key: objectId) as? T
        }
        return result
    }
    
    override func findEntityByQuery(query: Query) -> [T] {
        var results = [T]()
        executor.executeAndWait {
            results = (RealmResultsArray<Entity>(self.results(query)) as NSArray) as! [T]
        }
        return results
    }
    
    override func removeEntities(entities: [T]) -> Bool {
        var result = false
        executor.executeAndWait {
            try! self.realm.write {
                self.realm.delete(entities.map { $0 as! Entity })
            }
            result = true
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
