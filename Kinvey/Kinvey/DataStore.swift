//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public enum LiveEventType {
    case Create, Update, Delete
}

/// Class to interact with a specific collection in the backend.
public class DataStore<T: Persistable where T: NSObject> {
    
    public typealias ArrayCompletionHandler = ([T]?, ErrorType?) -> Void
    public typealias ObjectCompletionHandler = (T?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias UIntErrorTypeArrayCompletionHandler = (UInt?, [ErrorType]?) -> Void
    public typealias UIntArrayCompletionHandler = (UInt?, [T]?, [ErrorType]?) -> Void
    
    private let readPolicy: ReadPolicy
    private let writePolicy: WritePolicy
    
    /// Collection name that matches with the name in the backend.
    public let collectionName: String
    
    /// Client instance attached to the DataStore.
    public let client: Client
    
    /// DataStoreType defines how the DataStore will behave.
    public let type: DataStoreType
    
    private let cache: Cache
    private let sync: Sync
    
    /// TTL (Time to Live) defines a filter of how old the data returned from the DataStore can be.
    public var ttl: TTL? {
        didSet {
            cache.ttl = ttl != nil ? ttl!.1.toTimeInterval(ttl!.0) : 0
        }
    }
    
    /// Factory method that returns a `DataStore`.
    public class func getInstance(type: DataStoreType = .Cache, client: Client = sharedClient) -> DataStore {
        return DataStore<T>(type: type, client: client, filePath: nil, encryptionKey: client.encryptionKey)
    }
    
    private init(type: DataStoreType, client: Client, filePath: String?, encryptionKey: NSData?) {
        self.type = type
        self.client = client
        collectionName = T.kinveyCollectionName()
        cache = client.cacheManager.cache(collectionName, filePath: filePath)
        sync = client.syncManager.sync(collectionName, filePath: filePath)
        readPolicy = type.readPolicy
        writePolicy = type.writePolicy
    }
    
    /// Gets a single record using the `_id` of the record.
    public func findById(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        assert(id != "")
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = GetOperation(id: id, readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Gets a single record using the `_id` of the record.
    public func find(id: String, readPolicy: ReadPolicy? = nil, completionHandler: ObjectCompletionHandler? = nil) -> Request {
        return findById(id, readPolicy: readPolicy, completionHandler: completionHandler)
    }
    
    /// Gets a list of records that matches with the query passed by parameter.
    public func find(query: Query = Query(), deltaSet: Bool = true, readPolicy: ReadPolicy? = nil, completionHandler: ArrayCompletionHandler?) -> Request {
        let readPolicy = readPolicy ?? self.readPolicy
        let operation = FindOperation(query: Query(query: query, persistableType: T.self), deltaSet: deltaSet, readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Creates or updates a record.
    public func save(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: ObjectCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = SaveOperation(persistable: persistable, writePolicy: writePolicy, sync: sync, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a record.
    public func remove(persistable: T, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) throws -> Request {
        guard let id = persistable.kinveyObjectId else {
            throw Error.ObjectIdMissing
        }
        return removeById(id, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records.
    public func remove(array: [T], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        var ids: [String] = []
        for persistable in array {
            if let id = persistable.kinveyObjectId {
                ids.append(id)
            }
        }
        return removeById(ids, writePolicy:writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a record using the `_id` of the record.
    public func removeById(id: String, writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByIdOperation(objectId: id, writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes a list of records using the `_id` of the records.
    public func removeById(ids: [String], writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let query = Query(format: "\(T.idKey) IN %@", ids)
        return remove(query, writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Deletes a list of records that matches with the query passed by parameter.
    public func remove(query: Query = Query(), writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        let writePolicy = writePolicy ?? self.writePolicy
        let operation = RemoveByQueryOperation(query: Query(query: query, persistableType: T.self), writePolicy: writePolicy, sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
        return request
    }
    
    /// Deletes all the records.
    public func removeAll(writePolicy: WritePolicy? = nil, completionHandler: UIntCompletionHandler?) -> Request {
        return remove(writePolicy: writePolicy, completionHandler: completionHandler)
    }
    
    /// Sends to the backend all the pending records in the local cache.
    public func push(timeout timeout: NSTimeInterval? = nil, completionHandler: UIntErrorTypeArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, [KinveyError.InvalidDataStoreType])
            return LocalRequest()
        }
        
        let operation = PushOperation(sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(timeout: timeout, completionHandler: completionHandler)
        return request
    }
    
    /// Gets the records from the backend that matches with the query passed by parameter and saves locally in the local cache.
    public func pull(query: Query = Query(), completionHandler: DataStore<T>.ArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, KinveyError.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let operation = FindOperation(query: Query(query: query, persistableType: T.self), deltaSet: true, readPolicy: .ForceNetwork, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute(completionHandler)
        return request
    }
    
    /// Calls `push` and then `pull` methods, so it sends all the pending records in the local cache and then gets the records from the backend and saves locally in the local cache.
    public func sync(query: Query = Query(), completionHandler: UIntArrayCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, nil, [KinveyError.InvalidDataStoreType])
            return LocalRequest()
        }
        
        let requests = MultiRequest()
        let request = push() { count, errors in
            if let count = count where errors == nil || errors!.isEmpty {
                let request = self.pull(query) { results, error in
                    completionHandler?(count, results, error != nil ? [error!] : nil)
                }
                requests.addRequest(request)
            } else {
                completionHandler?(count, nil, errors)
            }
        }
        requests.addRequest(request)
        return requests
    }
    
    /// Deletes all the pending chances in the local cache.
    public func purge(query: Query = Query(), completionHandler: DataStore<T>.UIntCompletionHandler? = nil) -> Request {
        let completionHandler = dispatchAsyncMainQueue(completionHandler)
        guard type == .Sync else {
            completionHandler?(nil, Error.InvalidDataStoreType)
            return LocalRequest()
        }
        
        let operation = PurgeOperation(sync: sync, persistableType: T.self, cache: cache, client: client)
        let request = operation.execute { (count, error: ErrorType?) -> Void in
            if let count = count {
                self.pull(query) { (results, error) -> Void in
                    completionHandler?(count, error)
                }
            } else {
                completionHandler?(count, error)
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    private func dispatchAsyncMainQueue<R, E>(completionHandler: ((R, E) -> Void)? = nil) -> ((R, E) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj, error)
                })
            }
        }
        return nil
    }
    
    private func dispatchAsyncMainQueue<R>(completionHandler: ((R?, ErrorType?) -> Void)? = nil) -> ((AnyObject?, ErrorType?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj: AnyObject?, error: ErrorType?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj as? R, error)
                })
            }
        }
        return nil
    }
    
    private func dispatchAsyncMainQueue<R1, R2>(completionHandler: ((R1?, R2?, ErrorType?) -> Void)? = nil) -> ((R1?, R2?, ErrorType?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R1?, obj2: R2?, error: ErrorType?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj1, obj2, error)
                })
            }
        }
        return nil
    }
    
    private func dispatchAsyncMainQueue<R1, R2, R3>(completionHandler: ((R1?, R2?, R3?) -> Void)? = nil) -> ((R1?, R2?, R3?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj1: R1?, obj2: R2?, error: R3?) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj1, obj2, error)
                })
            }
        }
        return nil
    }
    
    var eventSourceLock = NSLock()
    
    var eventSource: EventSource? {
        willSet {
            if let eventSource = eventSource {
                eventSource.close()
            }
        }
    }
    
    var isSubscribed: Bool {
        get {
            return eventSource != nil //&& eventSource!.readyState != .Closed
        }
    }

    public func subscribe(eventHandler: ((LiveEventType?, T?, NSError?) -> Void)? = nil)
    {
        eventSourceLock.lock()
        eventSource = EventSource(url: "https://91d0823e.ngrok.io/appdata/\(client.appKey!)/\(T.kinveyCollectionName())", headers: [:])
        eventSource!.onMessage { [weak self] (id, event, data) in
            if let selfWeak = self,
                let jsonStr = data as NSString?,
                let data = jsonStr.dataUsingEncoding(NSUTF8StringEncoding),
                let msg = try! NSJSONSerialization.JSONObjectWithData(data, options: []) as? JsonDictionary,
                let op = msg["op"] as? String
            {
                switch op {
                case "create":
                    fallthrough
                case "update":
                    if let json = msg["data"] as? JsonDictionary,
                        let obj = T.fromJson(json) as? T
                    {
                        selfWeak.cache.saveEntity(T.toJson(persistable: obj))
                        let eventType: LiveEventType = op == "create" ? .Create : .Update
                        eventHandler?(eventType, obj, nil)
                    }
                    break
                case "delete":
                    if let id = msg["id"] as? String,
                        let json = selfWeak.cache.findEntity(id),
                        let obj = Operation.fromJson(T.self, json: json) as? T
                    {
                        eventHandler?(.Delete, obj, nil)
                        selfWeak.cache.removeEntity(json)
                    }
                    break
                default:
                    break
                }
            }
        }
        eventSource!.onError { [weak self] (error) in
            self?.eventSource = nil
            eventHandler?(nil, nil, error)
        }
        eventSourceLock.unlock()
    }
    
    deinit {
        if isSubscribed {
            unsubscribe()
        }
    }
    
    public func unsubscribe() {
        eventSourceLock.lock()
        eventSource = nil
        eventSourceLock.unlock()
    }
    
}
