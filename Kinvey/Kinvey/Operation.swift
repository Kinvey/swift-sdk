//
//  Operation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

let operationsQueue = OperationQueue(name: "Kinvey")

extension OperationQueue {
    
    convenience init(name: String) {
        self.init()
        self.name = name
    }
    
    func pendingBlockOperations(forCollection collectionName: String) -> [PendingBlockOperation] {
        return operationsQueue.operations.filter {
            $0 is PendingBlockOperation
        }.map {
            $0 as! PendingBlockOperation
        }.filter {
            $0.collectionName == collectionName
        }
    }
    
}

class AsyncBlockOperation : BlockOperation {
    
    convenience init(block: @escaping (AsyncBlockOperation) -> Void) {
        self.init()
        addExecutionBlock { [unowned self] in
            block(self)
        }
    }
    
    enum State: String {
        
        case ready = "Ready"
        case executing = "Executing"
        case finished = "Finished"
        
        var keyPath: String {
            return "is" + rawValue
        }
    }
    
    override var isAsynchronous: Bool {
        return true
    }
    
    var state = State.ready {
        willSet {
            willChangeValue(forKey: state.keyPath)
            willChangeValue(forKey: newValue.keyPath)
        }
        didSet {
            didChangeValue(forKey: oldValue.keyPath)
            didChangeValue(forKey: state.keyPath)
        }
    }
    
    override var isExecuting: Bool {
        return state == .executing
    }
    
    override var isFinished: Bool {
        return state == .finished
    }
    
    override func start() {
        if isCancelled {
            state = .finished
        } else {
            state = .ready
            main()
        }
    }
    
    override func main() {
        if isCancelled {
            state = .finished
        } else {
            state = .executing
            super.main()
        }
    }
    
}

class CollectionBlockOperation: BlockOperation {
    
    let collectionName: String
    
    init(collectionName: String, block: @escaping () -> Void) {
        self.collectionName = collectionName
        super.init()
        addExecutionBlock(block)
    }
    
}

internal class Operation<T: Persistable>: NSObject where T: NSObject {
    
    typealias ArrayCompletionHandler = ([T]?, Swift.Error?) -> Void
    typealias ObjectCompletionHandler = (T?, Swift.Error?) -> Void
    typealias UIntCompletionHandler = (UInt?, Swift.Error?) -> Void
    typealias UIntArrayCompletionHandler = (UInt?, [T]?, Swift.Error?) -> Void
    
    let cache: AnyCache<T>?
    let client: Client
    
    init(cache: AnyCache<T>? = nil, client: Client) {
        self.cache = cache
        self.client = client
    }
    
    func reduceToIdsLmts(_ jsonArray: [JsonDictionary]) -> [String : String] {
        var items = [String : String](minimumCapacity: jsonArray.count)
        for json in jsonArray {
            if let id = json[Entity.Key.entityId] as? String,
                let kmd = json[Entity.Key.metadata] as? JsonDictionary,
                let lmt = kmd[Metadata.Key.lastModifiedTime] as? String
            {
                items[id] = lmt
            }
        }
        return items
    }
    
    func computeDeltaSet(_ query: Query, refObjs: [String : String]) -> (created: Set<String>, updated: Set<String>, deleted: Set<String>) {
        guard let cache = cache else {
            return (created: Set<String>(), updated: Set<String>(), deleted: Set<String>())
        }
        let refKeys = Set<String>(refObjs.keys)
        let cachedObjs = cache.findIdsLmts(byQuery: query)
        let cachedKeys = Set<String>(cachedObjs.keys)
        let createdKeys = refKeys.subtracting(cachedKeys)
        let deletedKeys = cachedKeys.subtracting(refKeys)
        var updatedKeys = refKeys.intersection(cachedKeys)
        if updatedKeys.count > 0 {
            updatedKeys = Set<String>(updatedKeys.filter({ refObjs[$0] != cachedObjs[$0] }))
        }
        return (created: createdKeys, updated: updatedKeys, deleted: deletedKeys)
    }
    
    func fillObject(_ persistable: inout T) -> T {
        if persistable.entityId == nil {
            persistable.entityId = "\(ObjectIdTmpPrefix)\(UUID().uuidString)"
        }
        
        return persistable
    }
    
    func merge(_ persistableArray: inout [T], jsonArray: [JsonDictionary]) {
        if persistableArray.count == jsonArray.count && persistableArray.count > 0 {
            for (index, _) in persistableArray.enumerated() {
                merge(&persistableArray[index], json: jsonArray[index])
            }
        }
    }
    
    func merge(_ persistable: inout T, json: JsonDictionary) {
        let map = Map(mappingType: .fromJSON, JSON: json)
        persistable.mapping(map: map)
    }
    
}
