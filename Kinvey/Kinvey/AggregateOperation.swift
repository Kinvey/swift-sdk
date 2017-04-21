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
    
    init(aggregation: Aggregation, condition predicate: NSPredicate? = nil, readPolicy: ReadPolicy, cache: AnyCache<T>?, client: Client) {
        self.aggregation = aggregation
        self.predicate = predicate
        super.init(readPolicy: readPolicy, cache: cache, client: client)
    }
    
    func executeLocal(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = LocalRequest()
        request.execute { () -> Void in
            if let cache = self.cache {
                let result = cache.group(aggregation: aggregation, predicate: predicate)
                completionHandler?(.success(result))
            } else {
                completionHandler?(.success([]))
            }
        }
        return request
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildAppDataGroup(collectionName: T.collectionName(), keys: aggregation.keys, initialObject: aggregation.initialObject, reduceJSFunction: aggregation.reduceJSFunction, condition: predicate)
        request.execute() { data, response, error in
            if let response = response, response.isOK,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let result = json as? [JsonDictionary]
            {
                completionHandler?(.success(result))
            } else {
                completionHandler?(.failure(buildError(data, response, error, self.client)))
            }
        }
        return request
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
    
    var resultKey: String {
        switch self {
        case .custom(_, _, _):
            fatalError("Custom does not have a resultKey")
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
        }
    }
    
    var initialObject: JsonDictionary {
        switch self {
        case .custom(_, let initialObject, _):
            return initialObject
        case .count:
            return [resultKey : 0]
        case .sum:
            return [resultKey : 0.0]
        case .avg:
            return ["sum" : 0.0, "count" : 0]
        case .min:
            return [resultKey : "Infinity"]
        case .max:
            return [resultKey : "-Infinity"]
        }
    }
    
    var reduceJSFunction: String {
        switch self {
        case .custom(_, _, let reduceJSFunction):
            return reduceJSFunction
        case .count(_):
            return "function(doc, out) { out.\(resultKey)++; }"
        case .sum(_, let sum):
            return "function(doc, out) { out.\(resultKey) += doc.\(sum); }"
        case .avg(_, let avg):
            return "function(doc, out) { out.count++; out.sum += doc.\(avg); out.\(resultKey) = out.sum / out.count; }"
        case .min(_, let min):
            return "function(doc, out) { out.\(resultKey) = Math.min(out.\(resultKey), doc.\(min)); }"
        case .max(_, let max):
            return "function(doc, out) { out.\(resultKey) = Math.max(out.\(resultKey), doc.\(max)); }"
        }
    }
    
}

public typealias AggregationCustomResult<T: Persistable> = (value: T, custom: JsonDictionary)

public protocol CountType {}
extension Int: CountType {}
extension Int8: CountType {}
extension Int16: CountType {}
extension Int32: CountType {}
extension Int64: CountType {}

public typealias AggregationCountResult<T: Persistable, Count: CountType> = (value: T, count: Count)

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
