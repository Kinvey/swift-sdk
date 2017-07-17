//
//  Command.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

/// Class to interact with a custom endpoint in the backend.
open class CustomEndpoint {
    
    internal enum ParamsEnum {
        
        case json(JsonDictionary)
        case object(BaseMappable)
        
    }
    
    /// Parameter Wrapper
    open class Params {
        
        internal let value: ParamsEnum
        
        /**
         Sets the `value` enumeration to a JSON dictionary.
         - parameter json: JSON dictionary to be used as a parameter value
         */
        public init(_ json: JsonDictionary) {
            value = ParamsEnum.json(json)
        }
        
        /**
         Sets the `value` enumeration to any Mappable object.
         - parameter object: Mappable object to be used as a parameter value
         */
        public init(_ object: Mappable) {
            value = ParamsEnum.object(object)
        }
        
        /**
         Sets the `value` enumeration to any StaticMappable struct.
         - parameter object: StaticMappable struct to be used as a parameter value
         */
        public init(_ object: StaticMappable) {
            value = ParamsEnum.object(object)
        }
        
    }
    
    /// Completion handler block for execute custom endpoints.
    public typealias CompletionHandler<T> = (T?, Swift.Error?) -> Void
    
    private static func callEndpoint(
        _ name: String,
        params: Params? = nil,
        options: Options?,
        completionHandler: DataResponseCompletionHandler? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildCustomEndpoint(
            name,
            options: options
        )
        if let params = params {
            request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            switch params.value {
            case .json(let json):
                request.request.httpBody = try! JSONSerialization.data(withJSONObject: json.toJson())
            case .object(let object):
                request.request.httpBody = try! JSONSerialization.data(withJSONObject: object.toJSON().toJson())
            }
        }
        request.request.setValue(nil, forHTTPHeaderField: KinveyHeaderField.requestId)
        request.execute(completionHandler)
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Please use the generic version of execute(params: CustomEndpoint.Params?) method")
    open static func execute(
        _ name: String,
        params: JsonDictionary? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<JsonDictionary>? = nil
    ) -> Request {
        let params = params != nil ? Params(params!) : nil
        var request: Request!
        Promise<JsonDictionary> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: Options(
                    client: client
                )
            ) { data, response, error in
                if let response = response, response.isOK, let json: JsonDictionary = client.responseParser.parse(data) {
                    fulfill(json)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { json in
            completionHandler?(json, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Please use the generic version of execute(params: CustomEndpoint.Params?) method")
    open static func execute(
        _ name: String,
        params: JsonDictionary? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[JsonDictionary]>? = nil
    ) -> Request {
        let params = params != nil ? Params(params!) : nil
        var request: Request!
        Promise<[JsonDictionary]> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: Options(
                    client: client
                )
            ) { data, response, error in
                if let response = response, response.isOK, let json = client.responseParser.parseArray(data) {
                    fulfill(json)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { jsonArray in
            completionHandler?(jsonArray, nil)
        }.catch { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<JsonDictionary>? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            client: client
        ) { (result: Result<JsonDictionary, Swift.Error>) in
            switch result {
            case .success(let json):
                completionHandler?(json, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<JsonDictionary, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<JsonDictionary, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        var request: Request!
        Promise<JsonDictionary> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: options
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parse(data)
                {
                    fulfill(json)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { json in
            completionHandler?(.success(json))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[JsonDictionary]>? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            client: client
        ) { (result: Result<[JsonDictionary], Swift.Error>) in
            switch result {
            case .success(let json):
                completionHandler?(json, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[JsonDictionary], Swift.Error>) -> Void)? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<[JsonDictionary], Swift.Error>) -> Void)? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        var request: Request!
        Promise<[JsonDictionary]> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: options
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parseArray(data)
                {
                    fulfill(json)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { json in
            completionHandler?(.success(json))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    //MARK: BaseMappable: Mappable or StaticMappable
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<T>? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            client: client
        ) { (result: Result<T, Swift.Error>) in
            switch result {
            case .success(let obj):
                completionHandler?(obj, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        var request: Request!
        Promise<T> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: options
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let obj: T = client.responseParser.parse(data)
                {
                    fulfill(obj)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { obj in
            completionHandler?(.success(obj))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[T]>? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            client: client
        ) { (result: Result<[T], Swift.Error>) in
            switch result {
            case .success(let objArray):
                completionHandler?(objArray, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> Request {
        return execute(
            name,
            params: params,
            options: Options(
                client: client
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> Request {
        let client = options?.client ?? sharedClient
        var request: Request!
        Promise<[T]> { fulfill, reject in
            request = callEndpoint(
                name,
                params: params,
                options: options
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let objArray: [T] = client.responseParser.parse(data)
                {
                    fulfill(objArray)
                } else {
                    reject(buildError(data, response, error, client))
                }
            }
        }.then { objArray in
            completionHandler?(.success(objArray))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
}
