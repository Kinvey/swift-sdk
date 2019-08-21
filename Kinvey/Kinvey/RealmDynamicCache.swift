//
//  RealmDynamicCache.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

extension RealmCache: DynamicCacheType {
    
    private func countReferences(realm: Realm, objectClassName: String, nestedObject: Object, threshold: Int? = nil) -> Int {
        var count = 0
        for schema in realm.schema.objectSchema {
            guard schema.className != objectClassName else {
                continue
            }
            
            for property in schema.properties {
                guard property.objectClassName == objectClassName else {
                    continue
                }
                
                if property.isArray {
                    count += realm.dynamicObjects(schema.className).filter("ANY \(property.name) == %@", nestedObject).count
                } else {
                    count += realm.dynamicObjects(schema.className).filter("\(property.name) == %@", nestedObject).count
                }
                if let threshold = threshold, count > threshold {
                    return count
                }
            }
        }
        return count
    }
    
    internal func cascadeDelete(realm: Realm, entityType: String, entity: Object, deleteItself: Bool = true) {
        if let cascadeDeletable = entity as? CascadeDeletable {
            deleteAclAndMetadata(realm: realm, object: entity)
            try! cascadeDeletable.cascadeDelete(executor: RealmCascadeDeleteExecutor(realm: realm))
        } else if let schema = realm.schema[entityType] {
            signpost(.begin, log: osLog, name: "Cascade Delete", "%@", entityType)
            defer {
                signpost(.end, log: osLog, name: "Cascade Delete", "%@", entityType)
            }
            schema.properties.forEachAutoreleasepool { property in
                switch property.type {
                case .object:
                    if property.isArray,
                        let primaryKeyProperty = schema.primaryKeyProperty,
                        let entityId = entity[primaryKeyProperty.name],
                        let dynamicObject = realm.dynamicObject(ofType: entityType, forPrimaryKey: entityId),
                        let objectClassName = property.objectClassName,
                        let nestedArray = dynamicObject[property.name] as? List<DynamicObject>
                    {
                        cascadeDelete(
                            realm: realm,
                            entityType: objectClassName,
                            entities: nestedArray
                        )
                    } else if let objectClassName = property.objectClassName,
                        let nestedObject = entity[property.name] as? Object,
                        countReferences(realm: realm, objectClassName: objectClassName, nestedObject: nestedObject, threshold: 1) == 1
                    {
                        cascadeDelete(
                            realm: realm,
                            entityType: objectClassName,
                            entity: nestedObject
                        )
                    }
                default:
                    break
                }
            }
        }
        if deleteItself {
            realm.delete(entity)
        }
    }
    
    private func cascadeDelete(realm: Realm, entityType: String, entities: List<DynamicObject>) {
        for entity in entities {
            guard countReferences(realm: realm, objectClassName: entityType, nestedObject: entity, threshold: 1) == 1 else {
                continue
            }
            cascadeDelete(
                realm: realm,
                entityType: entityType,
                entity: entity
            )
        }
    }
    
    private func cascadeDelete(realm: Realm, entityType: String, entity: JsonDictionary, propertyMapping: PropertyMap) {
        propertyMapping.forEachAutoreleasepool { translatedKey, _ in
            if let property = properties[translatedKey],
                property.type == .object,
                let objectClassName = property.objectClassName,
                let entityId = entity[Entity.EntityCodingKeys.entityId],
                let dynamicObject = realm.dynamicObject(ofType: entityType, forPrimaryKey: entityId),
                let nestedObject = dynamicObject[translatedKey] as? Object,
                !(nestedObject is Entity)
            {
                cascadeDelete(
                    realm: realm,
                    entityType: objectClassName,
                    entity: nestedObject
                )
            } else if let property = properties[translatedKey],
                property.isArray,
                let objectClassName = property.objectClassName,
                let entityId = entity[Entity.EntityCodingKeys.entityId],
                let dynamicObject = realm.dynamicObject(ofType: entityType, forPrimaryKey: entityId),
                let nestedArray = dynamicObject[translatedKey] as? List<DynamicObject>
            {
                cascadeDelete(
                    realm: realm,
                    entityType: objectClassName,
                    entities: nestedArray
                )
            }
        }
    }
    
    func save(entities: AnyRandomAccessCollection<JsonDictionary>, syncQuery: SyncQuery?) {
        signpost(.begin, log: osLog, name: "Save Entities (JsonDictionary)")
        defer {
            signpost(.end, log: osLog, name: "Save Entities (JsonDictionary)")
        }
        log.debug("Saving \(entities.count) object(s)")
        let propertyMapping = T.propertyMapping()
        try! write { realm in
            try entities.forEachAutoreleasepool { entity in
                var translatedEntity = JsonDictionary()
                try propertyMapping.forEachAutoreleasepool { (translatedKey, tuple) in
                    let (key, transform) = tuple
                    if let transform = transform,
                        let value = transform.transformFromJSON(entity[key]) as? NSObject,
                        let property = self.properties[translatedKey],
                        !property.isArray,
                        let objectClassName = property.objectClassName,
                        let schema = realm.schema[objectClassName]
                    {
                        translatedEntity[translatedKey] = value.dictionaryWithValues(forKeys: schema.properties.map { $0.name })
                    } else if self.needsTranslation,
                        let array = entity[key] as? [Any],
                        let property = self.properties[translatedKey],
                        let objectClassName = property.objectClassName,
                        typesNeedsTranslation.contains(objectClassName)
                    {
                        translatedEntity[translatedKey] = array.map {
                            return ["value" : $0]
                        }
                    } else if let transform = transform {
                        translatedEntity[translatedKey] = transform.transformFromJSON(entity[key])
                    } else if let property = self.properties[translatedKey],
                        !property.isArray,
                        property.type == .object,
                        let clazz = ObjCRuntime.typeForPropertyName(self.entityType, propertyName: translatedKey),
                        let anyObjectClass = clazz as? (NSObject & JSONDecodable).Type,
                        let json = entity[key] as? [String : Any]
                    {
                        var obj = anyObjectClass.init()
                        try obj.refresh(from: json)
                        translatedEntity[translatedKey] = obj
                    } else {
                        translatedEntity[translatedKey] = entity[key]
                    }
                }
                self.cascadeDelete(
                    realm: realm,
                    entityType: self.entityTypeClassName,
                    entity: entity,
                    propertyMapping: propertyMapping
                )
                realm.dynamicCreate(self.entityTypeClassName, value: translatedEntity, update: .all)
            }
            self.saveQuery(syncQuery: syncQuery, realm: realm)
        }
    }
    
    func save(syncQuery: CacheType.SyncQuery) {
        saveQuery(syncQuery: syncQuery, realm: self.newRealm)
    }
    
    internal func saveQuery(syncQuery: SyncQuery?, realm: Realm) {
        guard let syncQuery = syncQuery else {
            return
        }
        
        let block: (String) -> Void = { entityTypeCollectionName in
            let realmSyncQuery = _QueryCache()
            realmSyncQuery.collectionName = entityTypeCollectionName
            realmSyncQuery.query = syncQuery.query.predicate?.asString
            realmSyncQuery.fields = syncQuery.query.fieldsAsString
            realmSyncQuery.lastSync = syncQuery.lastSync
            realmSyncQuery.generateKey()
            realm.add(realmSyncQuery, update: .all)
        }
        if realm.isInWriteTransaction {
            block(entityTypeCollectionName)
        } else {
            try! realm.write {
                block(entityTypeCollectionName)
            }
        }
    }
    
}
