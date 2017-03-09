//
//  Command.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

/// Class to interact with a custom endpoint in the backend.
open class CustomEndpoint {
    
    internal enum ParamsEnum {
        
        case json(JsonDictionary)
        case object(BaseMappable)
        
    }
    
    open class Params {
        
        internal let value: ParamsEnum
        
        public init(_ json: JsonDictionary) {
            value = ParamsEnum.json(json)
        }
        
        public init(_ object: Mappable) {
            value = ParamsEnum.object(object)
        }
        
        public init(_ object: StaticMappable) {
            value = ParamsEnum.object(object)
        }
        
    }
    
    /// Completion handler block for execute custom endpoints.
    public typealias CompletionHandler<T> = (Result<T>) -> Void
    
    private static func callEndpoint(_ name: String, params: Params? = nil, client: Client, completionHandler: DataResponseCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildCustomEndpoint(name)
        if let params = params {
            request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            switch params.value {
            case .json(let json):
                request.request.httpBody = try! JSONSerialization.data(withJSONObject: json.toJson(), options: [])
            case .object(let object):
                request.request.httpBody = try! JSONSerialization.data(withJSONObject: object.toJSON().toJson(), options: [])
            }
        }
        request.request.setValue(nil, forHTTPHeaderField: Header.requestId)
        request.execute(completionHandler)
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Please use the generic version of execute(params: CustomEndpoint.Params?) method")
    open static func execute(_ name: String, params: JsonDictionary? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<JsonDictionary>? = nil) -> Request {
        let params = params != nil ? Params(params!) : nil
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let json: JsonDictionary = client.responseParser.parse(data) {
                    completionHandler(.success(json))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Please use the generic version of execute(params: CustomEndpoint.Params?) method")
    open static func execute(_ name: String, params: JsonDictionary? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<[JsonDictionary]>? = nil) -> Request {
        let params = params != nil ? Params(params!) : nil
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let json = client.responseParser.parseArray(data) {
                    completionHandler(.success(json))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<JsonDictionary>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let json = client.responseParser.parse(data) {
                    completionHandler(.success(json))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<[JsonDictionary]>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let json = client.responseParser.parseArray(data) {
                    completionHandler(.success(json))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    //MARK: Mappable
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: Mappable>(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<T>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let obj: T = client.responseParser.parse(data) {
                    completionHandler(.success(obj))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: Mappable>(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<[T]>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let objArray: [T] = client.responseParser.parse(data) {
                    completionHandler(.success(objArray))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    //MARK: StaticMappable
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: StaticMappable>(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<T>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let obj: T = client.responseParser.parse(data) {
                    completionHandler(.success(obj))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: StaticMappable>(_ name: String, params: Params? = nil, client: Client = sharedClient, completionHandler: CompletionHandler<[T]>? = nil) -> Request {
        let request = callEndpoint(name, params: params, client: client) { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response , response.isOK, let objArray: [T] = client.responseParser.parse(data) {
                    completionHandler(.success(objArray))
                } else {
                    completionHandler(.failure(buildError(data, response, error, client)))
                }
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    fileprivate static func dispatchAsyncMainQueue<R>(_ completionHandler: ((R) -> Void)? = nil) -> ((R) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj) -> Void in
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(obj)
                })
            }
        }
        return nil
    }
    
}
