//
//  Command.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

/// Class to interact with a custom endpoint in the backend.
open class CustomEndpoint {
    
    /// Parameter Wrapper
    open class Params {
        
        internal let value: JsonDictionary
        
        /**
         Sets the `value` enumeration to a JSON dictionary.
         - parameter json: JSON dictionary to be used as a parameter value
         */
        public init(_ json: JsonDictionary) {
            value = json.toJson()
        }
        
        /**
         Sets the `value` enumeration to any Mappable object or StaticMappable struct.
         - parameter object: Mappable object or StaticMappable struct to be used as a parameter value
         */
        @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
        public convenience init<T>(_ object: T) where T: BaseMappable {
            self.init(object.toJSON())
        }
        
        public convenience init(_ object: JSONEncodable) throws {
            self.init(try object.encode())
        }
        
        public convenience init<T>(_ object: T) throws where T: Encodable {
            let data = try jsonEncoder.encode(object)
            let json = try JSONSerialization.jsonObject(with: data) as! JsonDictionary
            self.init(json)
        }
        
    }
    
    /// Completion handler block for execute custom endpoints.
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use Result<T, Swift.Error> instead")
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
            request.setBody(json: params.value)
        }
        request.request.setValue(nil, forHTTPHeaderField: KinveyHeaderField.requestId)
        request.execute(completionHandler)
        return AnyRequest(request)
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute(
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<JsonDictionary, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<JsonDictionary, Swift.Error>> {
        return execute(
            name,
            params: params,
            options: try! Options(client: client),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open class func execute(
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
                    let data = data,
                    let json = try? client.jsonParser.parseDictionary(from: data)
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute(
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[JsonDictionary], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[JsonDictionary], Swift.Error>> {
        return execute(
            name,
            params: params,
            options: try! Options(client: client),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open class func execute(
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
                    let data = data,
                    let json = try? client.jsonParser.parseDictionaries(from: data)
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
    
    // MARK: BaseMappable: Mappable or StaticMappable
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<T>? = nil
    ) -> AnyRequest<Result<T, Swift.Error>> where T: JSONDecodable {
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<T, Swift.Error>> where T: JSONDecodable {
        return execute(
            name,
            params: params,
            options: try! Options(client: client),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open class func execute<T>(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<T, Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<T, Swift.Error>> where T : JSONDecodable {
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
                    let data = data,
                    let obj = try? client.jsonParser.parseObject(T.self, from: data)
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: CompletionHandler<[T]>? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> where T: JSONDecodable {
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
    @available(*, deprecated, message: "Deprecated in version 3.17.0. Please use CustomEndpoint.execute(_:params:options:completionHandler:)")
    open class func execute<T: BaseMappable>(
        _ name: String,
        params: Params? = nil,
        client: Client = sharedClient,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> where T: JSONDecodable {
        return execute(
            name,
            params: params,
            options: try! Options(client: client),
            completionHandler: completionHandler
        )
    }
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open class func execute<T>(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> where T: JSONDecodable {
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
                    let data = data,
                    let objArray = try? client.jsonParser.parseObjects(T.self, from: data)
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
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    @discardableResult
    open class func execute<T>(
        _ name: String,
        params: Params? = nil,
        options: Options? = nil,
        completionHandler: ((Result<[T], Swift.Error>) -> Void)? = nil
    ) -> AnyRequest<Result<[T], Swift.Error>> where T: Decodable {
        let client = options?.client ?? sharedClient
        var request: AnyRequest<Result<[T], Swift.Error>>!
        Promise<[T]> { resolver in
            request = callEndpoint(
                name,
                params: params,
                options: options,
                resultType: Result<[T], Swift.Error>.self
            ) { data, response, error in
                do {
                    if let response = response,
                        response.isOK,
                        let data = data
                    {
                        let objArray = try jsonDecoder.decode([T].self, from: data)
                        resolver.fulfill(objArray)
                    } else {
                        resolver.reject(buildError(data, response, error, client))
                    }
                } catch {
                    resolver.reject(error)
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
