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
    
    open let validationStrategy: ValidationStrategy?
    
    fileprivate let fileURL: URL?
    
    internal let cache: AnyCache<T>?
    internal let sync: AnySync?
    
    fileprivate var deltaSet: Bool
    
    fileprivate let uuid = UUID()
    
    private let autoPagination: Bool
    
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
     - Parameters:
       - type: (Optional) Type for the new DataStore instance. Default value:
     `.cache`
       - deltaSet: (Optional) Enables delta set cache. Default value: `nil`
       - client: (Optional) `Client` instance to be used for all requests.
     Default value: `sharedClient`
       - tag: (Optional) Tag the store and separate stores in different tags.
     Default value: `defaultTag`
       - validationStrategy: (Optional) Defines a strategy to validate results upfront. Default value: `nil`
     - Returns: An instance of `DataStore` which can be a new instance or a cached instance if you are passing a `tag` parameter.
     */
    @available(*, deprecated: 3.0.22, message: "Please use `collection()` instead")
    open class func getInstance(
        _ type: StoreType = .cache,
        deltaSet: Bool? = nil,
        client: Client = sharedClient,
        tag: String = defaultTag,
        validationStrategy: ValidationStrategy? = nil
    ) -> DataStore {
        return collection(type, deltaSet: deltaSet, client: client, tag: tag)
    }

    /**
     Factory method that returns a `DataStore`.
     - parameter type: defines the data store type which will define the behavior of the `DataStore`. Default value: `Cache`
     - parameter deltaSet: Enables delta set cache which will increase performance and reduce data consumption. Default value: `false`
     - parameter client: define the `Client` to be used for all the requests for the `DataStore` that will be returned. Default value: `Kinvey.sharedClient`
     - parameter tag: A tag/nickname for your `DataStore` which will cache instances with the same tag name. Default value: `Kinvey.defaultTag`
     - parameter validationStrategy: (Optional) Defines a strategy to validate results upfront. Default value: `nil`
     - returns: An instance of `DataStore` which can be a new instance or a cached instance if you are passing a `tag` parameter.
     */
    open class func collection(
        _ type: StoreType = .cache,
        deltaSet: Bool? = nil,
        autoPagination: Bool = false,
        client: Client = sharedClient,
        tag: String = defaultTag,
        validationStrategy: ValidationStrategy? = nil
    ) -> DataStore {
        if !client.isInitialized() {
            fatalError("Client is not initialized. Call Kinvey.sharedClient.initialize(...) to initialize the client before creating a DataStore.")
        }
        let key = DataStoreTypeTag(persistableType: T.self, tag: tag, type: type)
        var dataStore = client.dataStoreInstances[key] as? DataStore
        if dataStore == nil {
            let fileURL = client.fileURL(tag)
            dataStore = DataStore<T>(
                type: type,
                deltaSet: deltaSet ?? false,
                autoPagination: autoPagination,
                client: client,
                fileURL: fileURL,
                encryptionKey: client.encryptionKey,
                validationStrategy: validationStrategy
            )
            client.dataStoreInstances[key] = dataStore
        }
        return dataStore!
    }
    
    /**
     Factory method that returns a new instance of a DataStore copying all the
     current configuration but for a new type.
     - parameter newType: Type for the new DataStore instance
     - returns: A new DataStore instance for the type specified
     */
    open func collection<NewType: Persistable>(
        newType: NewType.Type
    ) -> DataStore<NewType> where NewType: NSObject {
        return DataStore<NewType>(
            type: type,
            deltaSet: deltaSet,
            autoPagination: autoPagination,
            client: client,
            fileURL: fileURL,
            encryptionKey: client.encryptionKey,
            validationStrategy: validationStrategy
        )
    }
    
    fileprivate init(
        type: StoreType,
        deltaSet: Bool,
        autoPagination: Bool,
        client: Client,
        fileURL: URL?,
        encryptionKey: Data?,
        validationStrategy: ValidationStrategy?
    ) {
        self.type = type
        self.deltaSet = deltaSet
        self.autoPagination = autoPagination
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
        self.validationStrategy = validationStrategy
    }
    
    /**
     Gets a single record using the `_id` of the record.
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(byId id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping ObjectCompletionHandler) -> AnyRequest<Result<T, Swift.Error>> {
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
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(byId id: String, readPolicy: ReadPolicy? = nil, completionHandler: @escaping (Result<T, Swift.Error>) -> Void) -> AnyRequest<Result<T, Swift.Error>> {
        return find(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    private func validate(id: String) {
        if id.isEmpty {
            fatalError("id cannot be an empty string")
        }
    }
    
    /**
     Gets a single record using the `_id` of the record.
     
     PS: This method is just a shortcut for `findById()`
     - parameter id: The `_id` value of the entity to be find
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(
        _ id: String,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ObjectCompletionHandler
    ) -> AnyRequest<Result<T, Swift.Error>> {
        return find(
            id,
            readPolicy: readPolicy
        ) { (result: Result<T, Swift.Error>) in
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
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(
        _ id: String,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<T, Swift.Error>) -> Void
    ) -> AnyRequest<Result<T, Swift.Error>> {
        return find(
            id,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
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
    open func find(
        _ id: String,
        options: Options? = nil,
        completionHandler: @escaping (Result<T, Swift.Error>) -> Void
    ) -> AnyRequest<Result<T, Swift.Error>> {
        validate(id: id)
        
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let operation = GetOperation<T>(
            id: id,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
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
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ArrayCompletionHandler
    ) -> AnyRequest<Result<[T], Swift.Error>> {
        return find(
            query,
            deltaSet: deltaSet,
            readPolicy: readPolicy
        ) { (result: Result<[T], Swift.Error>) in
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
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use the `ReadPolicy` inferred from the store's type. Default value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use find(_:options:completionHandler:)")
    @discardableResult
    open func find(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[T], Swift.Error>) -> Void
    ) -> AnyRequest<Result<[T], Swift.Error>> {
        return find(
            query,
            options: Options(
                deltaSet: deltaSet,
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /**
     Gets a list of records that matches with the query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter deltaSet: Enforces delta set cache otherwise use the client's `deltaSet` value. Default value: `false`
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.7.0, message: "Please use AnyRandomAccessCollection<T> instead of Array<T> (or [T]) for completion handlers")
    @discardableResult
    open func find(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: @escaping (Result<[T], Swift.Error>) -> Void
    ) -> AnyRequest<Result<[T], Swift.Error>> {
        return find(query, options: options) { (result: Result<[T], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(.success(Array(results)))
            case .failure(let error):
                completionHandler(.failure(error))
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
    open func find(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: @escaping (Result<AnyRandomAccessCollection<T>, Swift.Error>) -> Void
    ) -> AnyRequest<Result<AnyRandomAccessCollection<T>, Swift.Error>> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let deltaSet = options?.deltaSet ?? self.deltaSet
        let operation = FindOperation<T>(
            query: Query(query: query, persistableType: T.self),
            deltaSet: deltaSet,
            autoPagination: autoPagination,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            completionHandler(result)
        }
        return request
    }
    
    /**
     Count of records that matches with the (optional) query parameter.
     - parameter query: (Optional) The query used to filter the results. When
     query is nil, gets the total count of the collection. Default value: `nil`
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use the `ReadPolicy` inferred from the store's type. Default value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use count(_:options:completionHandler:)")
    @discardableResult
    open func count(
        _ query: Query? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Result<Int, Swift.Error>> {
        return count(
            query,
            readPolicy: readPolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /**
     Count of records that matches with the (optional) query parameter.
     - parameter query: (Optional) The query used to filter the results. When
     query is nil, gets the total count of the collection. Default value: `nil`
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the `ReadPolicy` inferred from the store's type. Default
     value: `ReadPolicy` inferred from the store's type
     - parameter completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use count(_:options:completionHandler:)")
    @discardableResult
    open func count(
        _ query: Query? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Result<Int, Swift.Error>> {
        return count(
            query,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /**
     Gets a count of how many records that matches with the (optional) query passed by parameter.
     - parameter query: The query used to filter the results
     - parameter readPolicy: Enforces a different `ReadPolicy` otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the respose returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @discardableResult
    open func count(
        _ query: Query? = nil,
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Result<Int, Swift.Error>> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let operation = CountOperation<T>(
            query: Query(query: query ?? Query(), persistableType: T.self),
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return AnyRequest(request)
    }
    
    /**
     Custom aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - parameter keys: (Optional) Property names that should be grouped. Default
     value: `nil`
     - parameter initialObject: Sets an initial object that contains initial
     values needed for the reduce function
     - parameter reduceJSFunction: JavaScript reduce function that performs the
     aggregation
     - parameter condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:initialObject:reduceJSFunction:condition:options:completionHandler:)")
    @discardableResult
    open func group(
        keys: [String]? = nil,
        initialObject: JsonDictionary,
        reduceJSFunction: String,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationCustomResult<T>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            initialObject: initialObject,
            reduceJSFunction: reduceJSFunction,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationCustomResult<T>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Custom aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - parameter keys: (Optional) Property names that should be grouped. Default
     value: `nil`
     - parameter initialObject: Sets an initial object that contains initial
     values needed for the reduce function
     - parameter reduceJSFunction: JavaScript reduce function that performs the
     aggregation
     - parameter condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
     - parameter readPolicy: (Optional) Enforces a different `ReadPolicy`
     otherwise use the client's `ReadPolicy`. Default value: `nil`
     - parameter completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:initialObject:reduceJSFunction:condition:options:completionHandler:)")
    @discardableResult
    open func group(
        keys: [String]? = nil,
        initialObject: JsonDictionary,
        reduceJSFunction: String,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationCustomResult<T>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            initialObject: initialObject,
            reduceJSFunction: reduceJSFunction,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group(
        keys: [String]? = nil,
        initialObject: JsonDictionary,
        reduceJSFunction: String,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationCustomResult<T>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let keys = keys ?? []
        let aggregation: Aggregation = .custom(
            keys: keys,
            initialObject: initialObject,
            reduceJSFunction: reduceJSFunction
        )
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationCustomResult<T> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationCustomResult<T>(
                        value: T(JSON: json)!,
                        custom: json
                    )
                }
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
    
    /**
     Count aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - countType: Integer type to be return as a result count
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(count:countType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Count: CountType>(
        count keys: [String],
        countType: Count.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationCountResult<T, Count>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            count: keys,
            countType: countType,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationCountResult<T, Count>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Count aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - countType: Integer type to be return as a result count
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(count:countType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Count: CountType>(
        count keys: [String],
        countType: Count.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationCountResult<T, Count>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            count: keys,
            countType: countType,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group<Count: CountType>(
        count keys: [String],
        countType: Count.Type? = nil,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationCountResult<T, Count>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .count(keys: keys)
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationCountResult<T, Count> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationCountResult<T, Count>(
                        value: T(JSON: json)!,
                        count: json[aggregation.resultKey] as! Count
                    )
                }
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
    
    /**
     Sum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - sum: Property name used in the sum operation
       - sumType: Integer type to be return as a result sum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:sum:sumType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Sum: AddableType>(
        keys: [String],
        sum: String,
        sumType: Sum.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationSumResult<T, Sum>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            sum: sum,
            sumType: sumType,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationSumResult<T, Sum>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Sum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - sum: Property name used in the sum operation
       - sumType: Integer type to be return as a result sum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:sum:sumType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Sum: AddableType>(
        keys: [String],
        sum: String,
        sumType: Sum.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationSumResult<T, Sum>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            sum: sum,
            sumType: sumType,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group<Sum: AddableType>(
        keys: [String],
        sum: String,
        sumType: Sum.Type? = nil,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationSumResult<T, Sum>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .sum(keys: keys, sum: sum)
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationSumResult<T, Sum> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationSumResult<T, Sum>(
                        value: T(JSON: json)!,
                        sum: json[aggregation.resultKey] as! Sum
                    )
                }
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
    
    /**
     Average aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - avg: Property name used in the average operation
       - avgType: Integer type to be return as a result average
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:avg:avgType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Avg: AddableType>(
        keys: [String],
        avg: String,
        avgType: Avg.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationAvgResult<T, Avg>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            avg: avg,
            avgType: avgType,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationAvgResult<T, Avg>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Average aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - avg: Property name used in the average operation
       - avgType: Integer type to be return as a result average
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:avg:avgType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Avg: AddableType>(
        keys: [String],
        avg: String,
        avgType: Avg.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationAvgResult<T, Avg>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            avg: avg,
            avgType: avgType,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group<Avg: AddableType>(
        keys: [String],
        avg: String,
        avgType: Avg.Type? = nil,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationAvgResult<T, Avg>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .avg(keys: keys, avg: avg)
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationAvgResult<T, Avg> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationAvgResult<T, Avg>(
                        value: T(JSON: json)!,
                        avg: json[aggregation.resultKey] as! Avg
                    )
                }
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
    
    /**
     Minimum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - min: Property name used in the minimum operation
       - minType: Integer type to be return as a result minimum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:min:minType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Min: MinMaxType>(
        keys: [String],
        min: String,
        minType: Min.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationMinResult<T, Min>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            min: min,
            minType: minType,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationMinResult<T, Min>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Minimum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - min: Property name used in the minimum operation
       - minType: Integer type to be return as a result minimum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:min:minType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Min: MinMaxType>(
        keys: [String],
        min: String,
        minType: Min.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationMinResult<T, Min>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            min: min,
            minType: minType,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group<Min: MinMaxType>(
        keys: [String],
        min: String,
        minType: Min.Type? = nil,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationMinResult<T, Min>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .min(keys: keys, min: min)
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationMinResult<T, Min> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationMinResult<T, Min>(
                        value: T(JSON: json)!,
                        min: json[aggregation.resultKey] as! Min
                    )
                }
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
    
    /**
     Maximum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - max: Property name used in the maximum operation
       - maxType: Integer type to be return as a result maximum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:max:maxType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Max: MinMaxType>(
        keys: [String],
        max: String,
        maxType: Max.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping ([AggregationMaxResult<T, Max>]?, Swift.Error?) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            max: max,
            maxType: maxType,
            condition: condition,
            readPolicy: readPolicy
        ) { (result: Result<[AggregationMaxResult<T, Max>], Swift.Error>) in
            switch result {
            case .success(let results):
                completionHandler(results, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Maximum aggregation function.
     Note: this function does not work on local data. It must be run against the
     backend.
     - Parameters:
       - keys: Property names that should be grouped
       - max: Property name used in the maximum operation
       - maxType: Integer type to be return as a result maximum
       - condition: (Optional) Predicate that filter the records to be
     considered during the reduce function. Default value: `nil`
       - readPolicy: (Optional) Enforces a different `ReadPolicy` otherwise use
     the client's `ReadPolicy`. Default value: `nil`
       - completionHandler: Completion handler to be called once the
     response returns
     - returns: A `Request` instance which will allow cancel the request later
     */
    @available(*, deprecated: 3.6.0, message: "Please use group(keys:max:maxType:condition:options:completionHandler:)")
    @discardableResult
    open func group<Max: MinMaxType>(
        keys: [String],
        max: String,
        maxType: Max.Type? = nil,
        condition: NSPredicate? = nil,
        readPolicy: ReadPolicy? = nil,
        completionHandler: @escaping (Result<[AggregationMaxResult<T, Max>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        return group(
            keys: keys,
            max: max,
            maxType: maxType,
            condition: condition,
            options: Options(
                readPolicy: readPolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func group<Max: MinMaxType>(
        keys: [String],
        max: String,
        maxType: Max.Type? = nil,
        condition: NSPredicate? = nil,
        options: Options? = nil,
        completionHandler: @escaping (Result<[AggregationMaxResult<T, Max>], Swift.Error>) -> Void
    ) -> AnyRequest<Any> {
        let readPolicy = options?.readPolicy ?? self.readPolicy
        let aggregation: Aggregation = .max(keys: keys, max: max)
        let operation = AggregateOperation<T>(
            aggregation: aggregation,
            condition: condition,
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            switch result {
            case .success(let results):
                let array = results.map { (json) -> AggregationMaxResult<T, Max> in
                    var json = json
                    json[Entity.Key.entityId] = groupId
                    return AggregationMaxResult<T, Max>(
                        value: T(JSON: json)!,
                        max: json[aggregation.resultKey] as! Max
                    )
                }
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
    @available(*, deprecated: 3.6.0, message: "Please use save(_:options:completionHandler:) instead")
    @discardableResult
    open func save(
        _ persistable: T,
        writePolicy: WritePolicy? = nil,
        completionHandler: ObjectCompletionHandler? = nil
    ) -> AnyRequest<Any> {
        return save(
            persistable,
            writePolicy: writePolicy
        ) { (result: Result<T, Swift.Error>) in
            switch result {
            case .success(let obj):
                completionHandler?(obj, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Creates or updates a record.
    @available(*, deprecated: 3.6.0, message: "Please use save(_:options:completionHandler:) instead")
    @discardableResult
    open func save(
        _ persistable: T,
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        return save(
            persistable,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Creates or updates a record.
    @discardableResult
    open func save(
        _ persistable: T,
        options: Options? = nil,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        let writePolicy = options?.writePolicy ?? self.writePolicy
        let operation = SaveOperation<T>(
            persistable: persistable,
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    /// Deletes a record.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ persistable: T,
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) throws -> AnyRequest<Any> {
        return try remove(
            persistable,
            writePolicy: writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a record.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ persistable: T,
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) throws -> AnyRequest<Any> {
        return try remove(
            persistable,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a record.
    @discardableResult
    open func remove(
        _ persistable: T,
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) throws -> AnyRequest<Any> {
        guard let id = persistable.entityId else {
            log.error("Object Id is missing")
            throw Error.objectIdMissing
        }
        return remove(
            byId: id,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ array: [T],
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            array,
            writePolicy: writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ array: [T],
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return remove(
            array,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records.
    @discardableResult
    open func remove(
        _ array: [T],
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.entityId {
                ids.append(id)
            }
        }
        return remove(
            byIds: ids,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    @available(*, deprecated: 3.4.0, message: "Please use `remove(byId:)` instead")
    open func removeById(
        _ id: String,
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            byId: id,
            writePolicy: writePolicy,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a record using the `_id` of the record.
    @available(*, deprecated: 3.6.0, message: "Please use remove(byId:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        byId id: String,
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            byId: id,
            writePolicy: writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a record using the `_id` of the record.
    @available(*, deprecated: 3.6.0, message: "Please use remove(byId:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        byId id: String,
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return remove(
            byId: id,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a record using the `_id` of the record.
    @discardableResult
    open func remove(
        byId id: String,
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        validate(id: id)

        let writePolicy = options?.writePolicy ?? self.writePolicy
        let operation = RemoveByIdOperation<T>(
            objectId: id,
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
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
    open func removeById(
        _ ids: [String],
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            byIds: ids,
            writePolicy: writePolicy,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @available(*, deprecated: 3.6.0, message: "Please use remove(byIds:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        byIds ids: [String],
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            byIds: ids,
            writePolicy: writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @available(*, deprecated: 3.6.0, message: "Please use remove(byIds:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        byIds ids: [String],
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return remove(
            byIds: ids,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records using the `_id` of the records.
    @discardableResult
    open func remove(
        byIds ids: [String],
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        guard !ids.isEmpty else {
            DispatchQueue.main.async {
                completionHandler?(.failure(Error.invalidOperation(description: "ids cannot be an empty array")))
            }
            return LocalRequest()
        }
        
        let query = Query(format: "\(T.entityIdProperty()) IN %@", ids as AnyObject)
        return remove(
            query,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ query: Query = Query(),
        writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return remove(
            query,
            writePolicy: writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @available(*, deprecated: 3.6.0, message: "Please use remove(_:options:completionHandler:) instead")
    @discardableResult
    open func remove(
        _ query: Query = Query(),
        writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return remove(
            query,
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    @discardableResult
    open func remove(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        let writePolicy = options?.writePolicy ?? self.writePolicy
        let operation = RemoveByQueryOperation<T>(
            query: Query(query: query, persistableType: T.self),
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
        let request = operation.execute { result in
            DispatchQueue.main.async {
                completionHandler?(result)
            }
        }
        return request
    }
    
    /// Deletes all the records.
    @available(*, deprecated: 3.6.0, message: "Please use removeAll(options:completionHandler:) instead")
    @discardableResult
    open func removeAll(
        _ writePolicy: WritePolicy? = nil,
        completionHandler: IntCompletionHandler?
    ) -> AnyRequest<Any> {
        return removeAll(
            writePolicy
        ) { (result: Result<Int, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes all the records.
    @available(*, deprecated: 3.6.0, message: "Please use removeAll(options:completionHandler:) instead")
    @discardableResult
    open func removeAll(
        _ writePolicy: WritePolicy? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return removeAll(
            options: Options(
                writePolicy: writePolicy
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Deletes all the records.
    @discardableResult
    open func removeAll(
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)?
    ) -> AnyRequest<Any> {
        return remove(
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Sends to the backend all the pending records in the local cache.
    @discardableResult
    open func push(
        timeout: TimeInterval? = nil,
        completionHandler: UIntErrorTypeArrayCompletionHandler? = nil
    ) -> AnyRequest<Any> {
        return push(
            timeout: timeout
        ) { (result: Result<UInt, [Swift.Error]>) in
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
    open func push(
        timeout: TimeInterval? = nil,
        completionHandler: ((Result<UInt, [Swift.Error]>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        return push(
            options: Options(
                timeout: timeout
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Sends to the backend all the pending records in the local cache.
    @discardableResult
    open func push(
        options: Options? = nil,
        completionHandler: ((Result<UInt, [Swift.Error]>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        var request: Request!
        Promise<UInt> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(MultipleErrors(errors: [Error.invalidDataStoreType]))
            } else {
                let operation = PushOperation<T>(
                    sync: sync,
                    cache: cache,
                    options: options
                )
                request = operation.execute() { result in
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
    open func pull(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        completionHandler: DataStore<T>.ArrayCompletionHandler? = nil
    ) -> AnyRequest<Any> {
        return pull(
            query,
            options: Options(
                deltaSet: deltaSet
            )
        ) { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
            switch result {
            case .success(let entities):
                completionHandler?(Array(entities), nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    @available(*, deprecated: 3.7.0, message: "Please use AnyRandomAccessCollection<T> instead of Array<T> (or [T]) for completion handlers")
    @discardableResult
    open func pull(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        deltaSetCompletionHandler: (([T]) -> Void)? = nil,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        return pull(
            query,
            deltaSetCompletionHandler: {
                guard let deltaSetCompletionHandler = deltaSetCompletionHandler else {
                    return
                }
                
                deltaSetCompletionHandler(Array($0))
            },
            options: Options(
                deltaSet: deltaSet
            )
        ) { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
            guard let completionHandler = completionHandler else {
                return
            }
            
            switch result {
            case .success(let results):
                completionHandler(.success(Array(results)))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    @discardableResult
    open func pull(
        _ query: Query = Query(),
        deltaSetCompletionHandler: ((AnyRandomAccessCollection<T>) -> Void)? = nil,
        options: Options? = nil,
        completionHandler: ((Result<AnyRandomAccessCollection<T>, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        var request: Request!
        Promise<AnyRandomAccessCollection<T>> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(Error.invalidDataStoreType)
            } else if self.syncCount() > 0 {
                request = LocalRequest()
                reject(Error.invalidOperation(description: "You must push all pending sync items before new data is pulled. Call push() on the data store instance to push pending items, or purge() to remove them."))
            } else {
                let deltaSet = options?.deltaSet ?? self.deltaSet
                let operation = PullOperation<T>(
                    query: Query(query: query, persistableType: T.self),
                    deltaSet: deltaSet,
                    deltaSetCompletionHandler: deltaSetCompletionHandler,
                    autoPagination: autoPagination,
                    readPolicy: .forceNetwork,
                    validationStrategy: validationStrategy,
                    cache: cache,
                    options: options
                )
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
    open func sync(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        completionHandler: UIntArrayCompletionHandler? = nil
    ) -> AnyRequest<Any> {
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
    open func sync(
        _ query: Query = Query(),
        deltaSet: Bool? = nil,
        completionHandler: ((Result<(UInt, [T]), [Swift.Error]>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        return sync(
            query,
            options: Options(
                deltaSet: deltaSet
            )
        ) { (result: Result<(UInt, AnyRandomAccessCollection<T>), [Swift.Error]>) in
            guard let completionHandler = completionHandler else {
                return
            }
            
            switch result {
            case .success(let count, let results):
                completionHandler(.success((count, Array(results))))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    @available(*, deprecated: 3.7.0, message: "Please use AnyRandomAccessCollection<T> instead of Array<T> (or [T]) for completion handlers")
    @discardableResult
    open func sync(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<(UInt, [T]), [Swift.Error]>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        return sync(
            query,
            options: options
        ) { (result: Result<(UInt, AnyRandomAccessCollection<T>), [Swift.Error]>) in
            guard let completionHandler = completionHandler else {
                return
            }
            
            switch result {
            case .success(let count, let results):
                completionHandler(.success((count, Array(results))))
            case .failure(let error):
                completionHandler(.failure(error))
            }
        }
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    @discardableResult
    open func sync(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<(UInt, AnyRandomAccessCollection<T>), [Swift.Error]>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        let requests = MultiRequest()
        Promise<(UInt, AnyRandomAccessCollection<T>)> { fulfill, reject in
            if type == .network {
                requests += LocalRequest()
                reject(MultipleErrors(errors: [Error.invalidDataStoreType]))
            } else {
                let request = push(
                    options: options
                ) { (result: Result<UInt, [Swift.Error]>) in
                    switch result {
                    case .success(let count):
                        let request = self.pull(
                            query,
                            options: options
                        ) { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
                            switch result {
                            case .success(let array):
                                fulfill((count, array))
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
        }.then {
            completionHandler?(.success($0))
        }.catch { error in
            if let error = error as? MultipleErrors {
                completionHandler?(.failure(error.errors))
            } else {
                completionHandler?(.failure([error]))
            }
        }
        return requests
    }
    
    /// Deletes all the pending changes in the local cache.
    @discardableResult
    open func purge(
        _ query: Query = Query(),
        completionHandler: DataStore<T>.IntCompletionHandler? = nil
    ) -> AnyRequest<Any> {
        return purge(
            query
        ) { (result: Result<Int, Swift.Error>) in
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
    open func purge(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<Int, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Any> {
        var request: Request!
        Promise<Int> { fulfill, reject in
            if type == .network {
                request = LocalRequest()
                reject(Error.invalidDataStoreType)
            } else {
                let executor = Executor()
                
                let operation = PurgeOperation<T>(
                    sync: sync,
                    cache: cache,
                    options: options
                )
                request = operation.execute { result in
                    switch result {
                    case .success(let count):
                        executor.execute {
                            self.pull(
                                query,
                                options: options
                            ) { (result: Result<AnyRandomAccessCollection<T>, Swift.Error>) in
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
    
    private lazy var channelName: String = {
        return "\(self.client.appKey!).c-\(self.collectionName)"
    }()
    
    private func realtimeRouter() throws -> RealtimeRouter {
        guard let user = client.activeUser else {
            throw Error.invalidOperation(description: "Active User not found")
        }
        
        guard let realtimeRouter = user.realtimeRouter else {
            throw Error.invalidOperation(description: "Active User not register for realtime")
        }
        
        return realtimeRouter
    }
    
    func execute<Result>(request: HttpRequest<Result>) -> Promise<RealtimeRouter> {
        return Promise<RealtimeRouter> { fulfill, reject in
            do {
                let realtimeRouter = try self.realtimeRouter()
                request.execute() { (data, response, error) in
                    if let response = response, response.isOK {
                        fulfill(realtimeRouter)
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                }
            } catch {
                reject(error)
            }
        }
    }
    
    /**
     Subscribe and start listening to changes in the collection
     */
    @discardableResult
    open func subscribe(
        options: Options? = nil,
        subscription: @escaping () -> Void,
        onNext: @escaping (T) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let request = client.networkRequestFactory.buildAppDataSubscribe(
            collectionName: collectionName,
            deviceId: deviceId,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        execute(
            request: request
        ).then { realtimeRouter in
            realtimeRouter.subscribe(
                channel: self.channelName,
                context: self,
                onNext: {
                    if let dict = $0 as? [String : Any], let obj = T(JSON: dict) {
                        self.cache?.save(entity: obj)
                        onNext(obj)
                    }
                },
                onStatus: onStatus,
                onError: onError
            )
        }.then {
            subscription()
        }.catch { error in
            onError(error)
        }
        return AnyRequest(request)
    }
    
    /**
     Unsubscribe and stop listening changes in the collection
     */
    @discardableResult
    open func unsubscribe(
        options: Options? = nil,
        completionHandler: @escaping (Result<Void, Swift.Error>) -> Void
    ) -> AnyRequest<Result<Void, Swift.Error>> {
        let request = client.networkRequestFactory.buildAppDataUnSubscribe(
            collectionName: collectionName,
            deviceId: deviceId,
            options: options,
            resultType: Result<Void, Swift.Error>.self
        )
        execute(
            request: request
        ).then { realtimeRouter in
            realtimeRouter.unsubscribe(channel: self.channelName, context: self)
        }.then {
            completionHandler(.success($0))
        }.catch { error in
            completionHandler(.failure(error))
        }
        return AnyRequest(request)
    }

}

extension DataStore: Hashable {
    
    public var hashValue: Int {
        return uuid.hashValue
    }
    
    public static func ==(lhs: DataStore<T>, rhs: DataStore<T>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}
