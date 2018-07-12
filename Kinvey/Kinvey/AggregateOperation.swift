//
//  AggregateOperation.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-03-23.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

class AggregateOperation<T: Persistable>: ReadOperation<T, [JsonDictionary], Swift.Error>, ReadOperationType where T: NSObject {
    
    let aggregation: Aggregation
    let predicate: NSPredicate?
    
    typealias ResultType = Result<[JsonDictionary], Swift.Error>
    
    init(
        aggregation: Aggregation,
        condition predicate: NSPredicate? = nil,
        readPolicy: ReadPolicy,
        validationStrategy: ValidationStrategy?,
        cache: AnyCache<T>?,
        options: Options?
    ) {
        self.aggregation = aggregation
        self.predicate = predicate
        super.init(
            readPolicy: readPolicy,
            validationStrategy: validationStrategy,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let request = LocalRequest<Result<[JsonDictionary], Swift.Error>>()
        request.execute { () -> Void in
            let result: ResultType
            if let _ = self.cache {
                result = .failure(Error.invalidOperation(description: "Custom Aggregation not supported against local cache"))
            } else {
                result = .success([])
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> AnyRequest<ResultType> {
        let initialObject: JsonDictionary
        let reduceJSFunction: String
        do {
            initialObject = try aggregation.initialObject()
            reduceJSFunction = try aggregation.reduceJSFunction()
        } catch {
            let result: ResultType = .failure(error)
            let request = LocalRequest<ResultType>()
            request.result = result
            completionHandler?(result)
            return AnyRequest(request)
        }
        let request = client.networkRequestFactory.buildAppDataGroup(
            collectionName: try! T.collectionName(),
            keys: aggregation.keys,
            initialObject: initialObject,
            reduceJSFunction: reduceJSFunction,
            condition: predicate,
            options: options,
            resultType: ResultType.self
        )
        request.execute() { data, response, error in
            let result: ResultType
            if let response = response, response.isOK,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let resultValue = json as? [JsonDictionary]
            {
                result = .success(resultValue)
            } else {
                result = .failure(buildError(data, response, error, self.client))
            }
            request.result = result
            completionHandler?(result)
        }
        return AnyRequest(request)
    }
    
}

enum Aggregation {
    
    case custom(keys: [String], initialObject: JsonDictionary, reduceJSFunction: String)
    case count(keys: [String])
    case sum(keys: [String], sum: String)
    case avg(keys: [String], avg: String)
    case min(keys: [String], min: String)
    case max(keys: [String], max: String)
    
    var keys: [String] {
        switch self {
        case .custom(let keys, _, _),
             .count(let keys),
             .sum(let keys, _),
             .avg(let keys, _),
             .min(let keys, _),
             .max(let keys, _):
            return keys
        }
    }
    
    func resultKey() throws -> String {
        switch self {
        case .count:
            return "count"
        case .sum:
            return "sum"
        case .avg:
            return "avg"
        case .min:
            return "min"
        case .max:
            return "max"
        case .custom(_, _, _):
            throw Error.invalidOperation(description: "Custom does not have a resultKey")
        }
    }
    
    func initialObject() throws -> JsonDictionary {
        switch self {
        case .custom(_, let initialObject, _):
            return initialObject
        case .count:
            return [try resultKey() : 0]
        case .sum:
            return [try resultKey() : 0.0]
        case .avg:
            return ["sum" : 0.0, "count" : 0]
        case .min:
            return [try resultKey() : "Infinity"]
        case .max:
            return [try resultKey() : "-Infinity"]
        }
    }
    
    func reduceJSFunction() throws -> String {
        switch self {
        case .custom(_, _, let reduceJSFunction):
            return reduceJSFunction
        case .count(_):
            return "function(doc, out) { out.\(try resultKey())++; }"
        case .sum(_, let sum):
            return "function(doc, out) { out.\(try resultKey()) += doc.\(sum); }"
        case .avg(_, let avg):
            return "function(doc, out) { out.count++; out.sum += doc.\(avg); out.\(try resultKey()) = out.sum / out.count; }"
        case .min(_, let min):
            return "function(doc, out) { out.\(try resultKey()) = Math.min(out.\(try resultKey()), doc.\(min)); }"
        case .max(_, let max):
            return "function(doc, out) { out.\(try resultKey()) = Math.max(out.\(try resultKey()), doc.\(max)); }"
        }
    }
    
}

public typealias AggregationCustomResult<T: Persistable> = (value: T, custom: JsonDictionary)

/**
 Protocol that marks all types that are compatible as a Count type such as Int,
 Int8, Int16, Int32 and Int64
 */
public protocol CountType {}
extension Int: CountType {}
extension Int8: CountType {}
extension Int16: CountType {}
extension Int32: CountType {}
extension Int64: CountType {}

public typealias AggregationCountResult<T: Persistable, Count: CountType> = (value: T, count: Count)

/**
 Protocol that marks all types that are compatible as a Add type such as
 NSNumber, Double, Float, Int, Int8, Int16, Int32 and Int64
 */
public protocol AddableType {}
extension NSNumber: AddableType {}
extension Double: AddableType {}
extension Float: AddableType {}
extension Int: AddableType {}
extension Int8: AddableType {}
extension Int16: AddableType {}
extension Int32: AddableType {}
extension Int64: AddableType {}

public typealias AggregationSumResult<T: Persistable, Sum: AddableType> = (value: T, sum: Sum)
public typealias AggregationAvgResult<T: Persistable, Avg: AddableType> = (value: T, avg: Avg)

/**
 Protocol that marks all types that are compatible as a Min type such as
 NSNumber, Double, Float, Int, Int8, Int16, Int32, Int64, Date and NSDate
 */
public protocol MinMaxType {}
extension NSNumber: MinMaxType {}
extension Double: MinMaxType {}
extension Float: MinMaxType {}
extension Int: MinMaxType {}
extension Int8: MinMaxType {}
extension Int16: MinMaxType {}
extension Int32: MinMaxType {}
extension Int64: MinMaxType {}
extension Date: MinMaxType {}
extension NSDate: MinMaxType {}

public typealias AggregationMinResult<T: Persistable, Min: MinMaxType> = (value: T, min: Min)
public typealias AggregationMaxResult<T: Persistable, Max: MinMaxType> = (value: T, max: Max)
