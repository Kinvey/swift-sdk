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
    
    private static func callEndpoint<Result>(
        _ name: String,
        params: Params? = nil,
        options: Options?,
        resultType: Result.Type,
        completionHandler: DataResponseCompletionHandler? = nil
    ) -> AnyRequest<Result> {
        let client = options?.client ?? sharedClient
        let request = client.networkRequestFactory.buildCustomEndpoint(
            name,
            options: options,
            resultType: resultType
        )
        if let params = params {
            switch params.value {
            case .json(let json):
                request.setBody(json: json.toJson())
            case .object(let object):
                request.setBody(json: object.toJSON().toJson())
            }
        }
        request.request.setValue(nil, forHTTPHeaderField: KinveyHeaderField.requestId)
        request.execute(completionHandler)
        return AnyRequest(request)
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<JsonDictionary>? = nil
    ) -> AnyRequest<Result<JsonDictionary, Swift.Error>> {
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
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<JsonDictionary, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<JsonDictionary, Swift.Error>> {
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
    ) -> AnyRequest<Result<JsonDictionary, Swift.Error>> {
        let client = options?.client ?? sharedClient
        var request: AnyRequest<Result<JsonDictionary, Swift.Error>>!
        Promise<JsonDictionary> { resolver in
            request = callEndpoint(
                name,
                params: params,
                options: options,
                resultType: Result<JsonDictionary, Swift.Error>.self
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parse(data)
                {
                    resolver.fulfill(json)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { json in
            completionHandler?(.success(json))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[JsonDictionary]>? = nil
    ) -> AnyRequest<Result<[JsonDictionary], Swift.Error>> {
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
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[JsonDictionary], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[JsonDictionary], Swift.Error>> {
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
    ) -> AnyRequest<Result<[JsonDictionary], Swift.Error>> {
        let client = options?.client ?? sharedClient
        var request: AnyRequest<Result<[JsonDictionary], Swift.Error>>!
        Promise<[JsonDictionary]> { resolver in
            request = callEndpoint(
                name,
                params: params,
                options: options,
                resultType: Result<[JsonDictionary], Swift.Error>.self
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let json = client.responseParser.parseArray(data)
                {
                    resolver.fulfill(json)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { json in
            completionHandler?(.success(json))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    //MARK: BaseMappable: Mappable or StaticMappable
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<T>? = nil
    ) -> AnyRequest<Result<T, Swift.Error>> {
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
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<T, Swift.Error>> {
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
    ) -> AnyRequest<Result<T, Swift.Error>> {
        let client = options?.client ?? sharedClient
        var request: AnyRequest<Result<T, Swift.Error>>!
        Promise<T> { resolver in
            request = callEndpoint(
                name,
                params: params,
                options: options,
                resultType: Result<T, Swift.Error>.self
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let obj: T = client.responseParser.parse(data)
                {
                    resolver.fulfill(obj)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { obj in
            completionHandler?(.success(obj))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[T]>? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> {
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
    @available(*, deprecated: 3.17.0, message: "Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open static func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> {
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
    ) -> AnyRequest<Result<[T], Swift.Error>> {
        let client = options?.client ?? sharedClient
        var request: AnyRequest<Result<[T], Swift.Error>>!
        Promise<[T]> { resolver in
            request = callEndpoint(
                name,
                params: params,
                options: options,
                resultType: Result<[T], Swift.Error>.self
            ) { data, response, error in
                if let response = response,
                    response.isOK,
                    let objArray: [T] = client.responseParser.parse(data)
                {
                    resolver.fulfill(objArray)
                } else {
                    resolver.reject(buildError(data, response, error, client))
                }
            }
        }.done { objArray in
            completionHandler?(.success(objArray))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
}
