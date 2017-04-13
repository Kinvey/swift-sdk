//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

class DataStoreTypeTag: Hashable {
    
    let persistableType: Persistable.Type
    let tag: String
    let type: StoreType
    
    init(persistableType: Persistable.Type, tag: String, type: StoreType) {
        self.persistableType = persistableType
        self.tag = tag
        self.type = type
    }
    
    var hashValue: Int {
        var hash = NSDecimalNumber(value: 5)
        hash = 23 * hash + NSDecimalNumber(value: NSStringFromClass(persistableType as! AnyClass).hashValue)
        hash = 23 * hash + NSDecimalNumber(value: tag.hashValue)
        hash = 23 * hash + NSDecimalNumber(value: type.hashValue)
        return hash.hashValue
    }
    
}

func +(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.adding(rhs)
}

func *(lhs: NSDecimalNumber, rhs: NSDecimalNumber) -> NSDecimalNumber {
    return lhs.multiplying(by: rhs)
}

func ==(lhs: DataStoreTypeTag, rhs: DataStoreTypeTag) -> Bool {
    return lhs.persistableType == rhs.persistableType &&
        lhs.tag == rhs.tag &&
        lhs.type == rhs.type
}

/// Class to interact with a specific collection in the backend.
open class DataStore<T: Persistable> where T: NSObject {
    
    public typealias ArrayCompletionHandler = ([T]?, Swift.Error?) -> Void
    public typealias ObjectCompletionHandler = (T?, Swift.Error?) -> Void
    public typealias IntCompletionHandler = (Int?, Swift.Error?) -> Void
    public typealias UIntErrorTypeArrayCompletionHandler = (UInt?, [Swift.Error]?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, [Swift.Error]?) -> Void
    
    fileprivate let readPolicy: ReadPolicy
    fileprivate let writePolicy: WritePolicy
    
    /// Collection name that matches with the name in the backend.
    open let collectionName: String
    
    /// Client instance attached to the DataStore.
    open let client: Client
    
    /// DataStoreType defines how the DataStore will behave.
    open let type: StoreType
    
    fileprivate let fileURL: URL?
    
    internal let cache: AnyCache<T>?
    internal let sync: AnySync?
    
    fileprivate var deltaSet: Bool
    
    /// TTL (Time to Live) defines a filter of how old the data returned from the DataStore can be.
    open var ttl: TTL? {
        didSet {
            if let cache = cache {
                if let (value, unit) = ttl {
                    cache.ttl = unit.toTimeInterval(value)
                } else {
                    cache.ttl = nil
                }
            }
        }
    }
    
    /**
     Deprecated method. Please use `collection()` instead.
     */
    @available(*, deprecated: 3.0.22, message: "Please use `collection()` instead")
    open class func getInstance(_ type: StoreType = .cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        return collection(type, deltaSet: deltaSet, client: client, tag: tag)
    }

    /**
     Factory method that returns a `DataStore`.
     - parameter type: defines the data store type which will define the behavior of the `DataStore`. Default value: `Cache`
     - parameter deltaSet: Enables delta set cache which will increase performance and reduce data consumption. Default value: `false`
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter tag: A tag/nickname for your `DataStore` which will cache instances with the same tag name. Default value: `Kinvey.defaultTag`
     - returns: An instance of `DataStore` which can be a new instance or a cached instance if you are passing a `tag` parameter.
     */
    open class func collection(_ type: StoreType = .cache, deltaSet: Bool? = nil, client: Client = sharedClient, tag: String = defaultTag) -> DataStore {
        if !client.isInitialized() {
            let message = "Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before creating a DataStore."
            log.severe(message)
            fatalError(message)
        }
        let key = DataStoreTypeTag(persistableType: T.self, tag: tag, type: type)
        var dataStore = client.dataStoreInstances[key] as? DataStore
        if dataStore == nil {
            let fileURL = client.fileURL(tag)
            dataStore = DataStore<T>(type: type, deltaSet: deltaSet ?? false, client: client, fileURL: fileURL, encryptionKey: client.encryptionKey)
            client.dataStoreInstances[key] = dataStore
        }
        return dataStore!
    }
    
    open func collection<NewType: Persistable>(newType: NewType.Type) -> DataStore<NewType> where NewType: NSObject {
        return DataStore<NewType>(type: type, deltaSet: deltaSet, client: client, fileURL: fileURL, encryptionKey: client.encryptionKey)
    }
    
    fileprivate init(type: StoreType, deltaSet: Bool, client: Client, fileURL: URL?, encryptionKey: Data?) {
        self.type = type
        self.deltaSet = deltaSet
        self.client = client
        self.fileURL = fileURL
        collectionName = T.collectionName()
        if type != .network, let _ = T.self as? Entity.Type {
            cache = client.cacheManager.cache(fileURL: fileURL, type: T.self)
            sync = client.syncManager.sync(fileURL: fileURL, type: T.self)
        } else {
            cache = nil
            sync = nil
        }
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    /**
     Gets a single record using the `_id` of the record.
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(byId id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ObjectCompletionHandler) -> Request {
        return find(byId: id, readPolicy: readPolicy) { (result: Result<T, Swift.Error>) in
            switch result {
            case .success(let obj):
                completionHandler(obj, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Gets a single record using the `_id` of the record.
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(byId id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<T, Swift.Error>) -> Void) -> Request {
        return find(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    private func validate(id: String) {
        if id.isEmpty {
            let message = "id cannot be an empty string"
            log.severe(message)
            fatalError(message)
        }
    }
    
    /**
     Gets a single record using the `_id` of the record.
     
     PS: This method is just a shortcut for `findById()`
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ObjectCompletionHandler) -> Request {
        return find(id, readPolicy: readPolicy) { (result: Result<T, Swift.Error>) in
            switch result {
            case .success(let obj):
                completionHandler(obj, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Gets a single record using the `_id` of the record.
     
     PS: This method is just a shortcut for `findById()`
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<T, Swift.Error>) -> Void) -> Request {
        validate(id: id)
        
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation<T>(id: id, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
        return request
    }
    
    /**
     Gets a list of records that matches with the query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter deltaSet: Enforces delta set cache otherwise use the client's `deltaSet` value. Default value: `false`
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ query: Query = Query(), deltaSet: Bool? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ArrayCompletionHandler) -> Request {
        return find(query, deltaSet: deltaSet, readPolicy: readPolicy) { (result: Result<[T], Swift.Error>) in
            switch result {
            case .success(let objs):
                completionHandler(objs, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Gets a list of records that matches with the query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter deltaSet: Enforces delta set cache otherwise use the client's `deltaSet` value. Default value: `false`
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func find(_ query: Query = Query(), deltaSet: Bool? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[T], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let deltaSet = deltaSet ?? self.deltaSet
        let operation = FindOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler(result)
            }
        }
        return request
    }
    
    /**
     Gets a count of how many records that matches with the (optional) query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func count(_ query: Query? = nil, readPolicy: ReadPolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return count(query, readPolicy: readPolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     Gets a count of how many records that matches with the (optional) query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func count(_ query: Query? = nil, readPolicy: ReadPolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = CountOperation<T>(query: query, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    @discardableResult
    open func group(keys: [String]? = nil, initialObject: JsonDictionary, reduceJSFunction: String, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ([AggregationCustomResult<T>]?, Swift.Error?) -> Void) -> Request {
        return group(keys: keys, initialObject: initialObject, reduceJSFunction: reduceJSFunction, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationCustomResult<T>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group(keys: [String]? = nil, initialObject: JsonDictionary, reduceJSFunction: String, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[AggregationCustomResult<T>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let keys = keys ?? []
        let aggregation: Aggregation = .custom(keys: keys, initialObject: initialObject, reduceJSFunction: reduceJSFunction)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationCustomResult<T>(value: T(JSON: $0)!, custom: $0) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    @discardableResult
    open func group<Count: CountType>(count keys: [String], countType: Count.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping
        ([AggregationCountResult<T, Count>]?, Swift.Error?) -> Void) -> Request {
        return group(count: keys, countType: countType, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationCountResult<T, Count>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group<Count: CountType>(count keys: [String], countType: Count.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping
        (Result<[AggregationCountResult<T, Count>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .count(keys: keys)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationCountResult<T, Count>(value: T(JSON: $0)!, count: $0[aggregation.resultKey] as! Count) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    @discardableResult
    open func group<Sum: AddableType>(keys: [String], sum: String, sumType: Sum.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ([AggregationSumResult<T, Sum>]?, Swift.Error?) -> Void) -> Request {
        return group(keys: keys, sum: sum, sumType: sumType, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationSumResult<T, Sum>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group<Sum: AddableType>(keys: [String], sum: String, sumType: Sum.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[AggregationSumResult<T, Sum>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .sum(keys: keys, sum: sum)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationSumResult<T, Sum>(value: T(JSON: $0)!, sum: $0[aggregation.resultKey] as! Sum) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    @discardableResult
    open func group<Avg: AddableType>(keys: [String], avg: String, avgType: Avg.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ([AggregationAvgResult<T, Avg>]?, Swift.Error?) -> Void) -> Request {
        return group(keys: keys, avg: avg, avgType: avgType, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationAvgResult<T, Avg>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group<Avg: AddableType>(keys: [String], avg: String, avgType: Avg.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[AggregationAvgResult<T, Avg>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .avg(keys: keys, avg: avg)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationAvgResult<T, Avg>(value: T(JSON: $0)!, avg: $0[aggregation.resultKey] as! Avg) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    @discardableResult
    open func group<Min: MinMaxType>(keys: [String], min: String, minType: Min.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ([AggregationMinResult<T, Min>]?, Swift.Error?) -> Void) -> Request {
        return group(keys: keys, min: min, minType: minType, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationMinResult<T, Min>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group<Min: MinMaxType>(keys: [String], min: String, minType: Min.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[AggregationMinResult<T, Min>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .min(keys: keys, min: min)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationMinResult<T, Min>(value: T(JSON: $0)!, min: $0[aggregation.resultKey] as! Min) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    @discardableResult
    open func group<Max: MinMaxType>(keys: [String], max: String, maxType: Max.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ([AggregationMaxResult<T, Max>]?, Swift.Error?) -> Void) -> Request {
        return group(keys: keys, max: max, maxType: maxType, condition: condition, readPolicy: readPolicy) { (result: Result<[AggregationMaxResult<T, Max>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    @discardableResult
    open func group<Max: MinMaxType>(keys: [String], max: String, maxType: Max.Type? = nil, condition: NSPredicate? = nil, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<[AggregationMaxResult<T, Max>], Swift.Error>) -> Void) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .max(keys: keys, max: max)
        let operation = AggregateOperation<T>(aggregation: aggregation, condition: condition, readPolicy: readPolicy, cache: cache, client: client)
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { AggregationMaxResult<T, Max>(value: T(JSON: $0)!, max: $0[aggregation.resultKey] as! Max) }
                DispatchQueue.main.async {
                    completionHandler(.success(array))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completionHandler(.failure(error))
                }
            }
        }
        return request
    }
    
    /// Creates or updates a record.
    @discardableResult
    open func save(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        return save(persistable, writePolicy: writePolicy) { (result: Result<T, Swift.Error>) in
            switch result {
            case .success(let obj):
                completionHandler?(obj, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Creates or updates a record.
    @discardableResult
    open func save(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    /// Deletes a record.
    @discardableResult
    open func remove(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) throws -> Request {
        return try remove(persistable, writePolicy: writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a record.
    @discardableResult
    open func remove(_ persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) throws -> Request {
        guard let id = persistable.entityId else {
            log.error("Object Id is missing")
            throw Error.objectIdMissing
        }
        return remove(byId: id, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records.
    @discardableResult
    open func remove(_ array: [T], writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(array, writePolicy: writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records.
    @discardableResult
    open func remove(_ array: [T], writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.entityId {
                ids.append(id)
            }
        }
        return remove(byIds: ids, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    @available(*, deprecated: 3.4.0, message: "Please use `remove(byId:)` instead")
    open func removeById(_ id: String, writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(byId: id, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    open func remove(byId id: String, writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(byId: id, writePolicy: writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    open func remove(byId id: String, writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        validate(id: id)

        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByIdOperation<T>(objectId: id, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @discardableResult
    @available(*, deprecated: 3.4.0, message: "Please use `remove(byIds:)` instead")
    open func removeById(_ ids: [String], writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(byIds: ids, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @discardableResult
    open func remove(byIds ids: [String], writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(byIds: ids, writePolicy: writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @discardableResult
    open func remove(byIds ids: [String], writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        if ids.isEmpty {
            let message = "ids cannot be an empty array"
            log.severe(message)
            fatalError(message)
        }
        
        let query = Query(format: "\(T.entityIdProperty()) IN %@", ids as AnyObject)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @discardableResult
    open func remove(_ query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return remove(query, writePolicy: writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @discardableResult
    open func remove(_ query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByQueryOperation<T>(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    /// Deletes all the records.
    @discardableResult
    open func removeAll(_ writePolicy: WritePolicy? = nil, completionHandler: IntCompletionHandler?) -> Request {
        return removeAll(writePolicy) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes all the records.
    @discardableResult
    open func removeAll(_ writePolicy: WritePolicy? = nil, completionHandler: ((Result<Int, Swift.Error>) -> Void)?) -> Request {
        return remove(writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Sends to the backend all the pending records in the local cache.
    @discardableResult
    open func push(timeout: TimeInterval? = nil, completionHandler: UIntErrorTypeArrayCompletionHandler? = nil) -> Request {
        return push(timeout: timeout) { (result: Result<UInt, [Swift.Error]>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let errors):
                completionHandler?(nil, errors)
            }
        }
    }
    
    /// Sends to the backend all the pending records in the local cache.
    @discardableResult
    open func push(timeout: TimeInterval? = nil, completionHandler: ((Result<UInt, [Swift.Error]>) -> Void)? = nil) -> Request {
        var request: Request!
        Promise<UInt> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(MultipleErrors(errors: [Error.invalidDataStoreType]))
            } else {
                let operation = PushOperation<T>(sync: sync, cache: cache, client: client)
                request = operation.execute(timeout: timeout) { result in
                    switch result {
                    case .success(let count):
                        fulfill(count)
                    case .failure(let errors):
                        reject(MultipleErrors(errors: errors))
                    }
                }
            }
        }.then { count in
            completionHandler?(.success(count))
        }.catch { error in
            let error = error as! MultipleErrors
            completionHandler?(.failure(error.errors))
        }
        return request
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    @discardableResult
    open func pull(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        return pull(query, deltaSet: deltaSet) { (result: Result<[T], Swift.Error>) in
            switch result {
            case .success(let array):
                completionHandler?(array, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    @discardableResult
    open func pull(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil) -> Request {
        var request: Request!
        Promise<[T]> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(Error.invalidDataStoreType)
            } else if self.syncCount() > 0 {
                request = LocalRequest()
                reject(Error.invalidOperation(description: "You must push all pending sync items before new data is pulled. Call push() on the data store instance to push pending items, or purge() to remove them."))
            } else {
                let deltaSet = deltaSet ?? self.deltaSet
                let operation = PullOperation<T>(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: .forceNetwork, cache: cache, client: client)
                request = operation.execute { result in
                    switch result {
                    case .success(let array):
                        fulfill(array)
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        }.then { array in
            completionHandler?(.success(array))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Returns the number of changes not synced yet.
    open func syncCount() -> UInt {
        if let sync = sync {
            return UInt(sync.pendingOperations().count)
        }
        return 0
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    @discardableResult
    open func sync(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        return sync(query, deltaSet: deltaSet) { (result: Result<(UInt, [T]), [Swift.Error]>) in
            switch result {
            case .success(let count, let array):
                completionHandler?(count, array, nil)
            case .failure(let errors):
                completionHandler?(nil, nil, errors)
            }
        }
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    @discardableResult
    open func sync(_ query: Query = Query(), deltaSet: Bool? = nil, completionHandler: ((Result<(UInt, [T]), [Swift.Error]>) -> Void)? = nil) -> Request {
        let requests = MultiRequest()
        Promise<(UInt, [T])> { fulfill, reject in
            if type == .network {
                requests += LocalRequest()
                reject(MultipleErrors(errors: [Error.invalidDataStoreType]))
            } else {
                let request = push() { (result: Result<UInt, [Swift.Error]>) in
                    switch result {
                    case .success(let count):
                        let deltaSet = deltaSet ?? self.deltaSet
                        let request = self.pull(query, deltaSet: deltaSet) { (result: Result<[T], Swift.Error>) in
                            switch result {
                            case .success(let array):
                                fulfill(count, array)
                            case .failure(let error):
                                reject(error)
                            }
                        }
                        requests.addRequest(request)
                    case .failure(let errors):
                        reject(MultipleErrors(errors: errors))
                    }
                }
                requests += request
            }
        }.then { count, array in
            completionHandler?(.success(count, array))
        }.catch { error in
            let error = error as! MultipleErrors
            completionHandler?(.failure(error.errors))
        }
        return requests
    }
    
    /// Deletes all the pending changes in the local cache.
    @discardableResult
    open func purge(_ query: Query = Query(), completionHandler: DataStore<T>.IntCompletionHandler? = nil) -> Request {
        return purge(query) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes all the pending changes in the local cache.
    @discardableResult
    open func purge(_ query: Query = Query(), completionHandler: ((Result<Int, Swift.Error>) -> Void)? = nil) -> Request {
        var request: Request!
        Promise<Int> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(Error.invalidDataStoreType)
            } else {
                let executor = Executor()
                
                let operation = PurgeOperation<T>(sync: sync, cache: cache, client: client)
                request = operation.execute { result in
                    switch result {
                    case .success(let count):
                        executor.execute {
                            self.pull(query) { (result: Result<[T], Swift.Error>) in
                                switch result {
                                case .success:
                                    fulfill(count)
                                case .failure(let error):
                                    reject(error)
                                }
                            }
                        }
                    case .failure(let error):
                        reject(error)
                    }
                }
            }
        }.then { count in
            completionHandler?(.success(count))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Clear all data for all collections.
    open class func clearCache(_ tag: String? = nil, client: Client = sharedClient) {
        client.cacheManager.clearAll(tag)
    }

    /// Clear all data for the collection attached to the DataStore.
    open func clearCache(query: Query? = nil) {
        cache?.clear(query: query)
    }

}
