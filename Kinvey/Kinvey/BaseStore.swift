//
//  BaseStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import UIKit

public class BaseStore<T: Persistable>: NSObject, Store {
    
    public typealias ArrayCompletionHandler = ([T]?, NSError?) -> Void
    public typealias ObjectCompletionHandler = (T?, NSError?) -> Void
    public typealias IntCompletionHandler = (Int?, NSError?) -> Void
    
    public let collectionName: String
    public let client: Client
    
    public required init(collectionName: String, client: Client = Kinvey.sharedClient()) {
        self.collectionName = collectionName
        self.client = client
    }
    
    public func get(id: String, completionHandler: ObjectCompletionHandler?) {
        let url = Client.Endpoint.AppDataById(client, collectionName, id).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            var obj: T? = nil
            if self.client.responseParser.isResponseOk(response) {
                obj = self.client.responseParser.parse(data, type: T.self)
            }
            if let completionHandler = completionHandler {
                completionHandler(obj, error)
            }
        }
    }
    
    public func find(query: Query, completionHandler: ArrayCompletionHandler?) {
        let url = Client.Endpoint.AppDataByQuery(client, collectionName, query).url()
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            var obj: [T]? = nil
            if self.client.responseParser.isResponseOk(response) {
                obj = self.client.responseParser.parseArray(data, type: T.self)
            }
            if let completionHandler = completionHandler {
                completionHandler(obj, error)
            }
        }
    }
    
    public func save(persistable: T, completionHandler: ObjectCompletionHandler?) {
        let url = Client.Endpoint.AppData(client, collectionName).url()
        let request = NSMutableURLRequest(URL: url!)
        let bodyObject = persistable.toJson()
        
        request.HTTPMethod = bodyObject[Kinvey.PersistableIdKey] == nil ? "POST" : "PUT"
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        client.networkTransport.execute(request) { (data, response, error) -> Void in
            var obj: T? = nil
            if self.client.responseParser.isResponseOk(response) {
                obj = self.client.responseParser.parse(data, type: T.self)
                if let obj = obj {
                    persistable.merge(obj)
                }
            }
            if let completionHandler = completionHandler {
                completionHandler(persistable, error)
            }
        }
    }
    
    public func save(persistable: [T], completionHandler: ArrayCompletionHandler?) {
    }
    
    public func remove(persistable: T, completionHandler: IntCompletionHandler?) {
    }
    
    public func remove(array: [T], completionHandler: IntCompletionHandler?) {
    }
    
    public func remove(query: Query, completionHandler: IntCompletionHandler?) {
    }
    
    //MARK: - Dispatch Async To
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: ObjectCompletionHandler? = nil) -> ObjectCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { obj, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(obj, error)
                })
            }
        }
        return completionHandler
    }
    
    internal func dispatchAsyncTo(queue queue: dispatch_queue_t = dispatch_get_main_queue(), _ completionHandler: ArrayCompletionHandler? = nil) -> ArrayCompletionHandler? {
        var completionHandler = completionHandler
        if let originalCompletionHandler = completionHandler {
            completionHandler = { objs, error in
                dispatch_async(queue, { () -> Void in
                    originalCompletionHandler(objs, error)
                })
            }
        }
        return completionHandler
    }

}
