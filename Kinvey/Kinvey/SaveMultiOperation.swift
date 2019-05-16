//
//  SaveMultiOperation.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-05-13.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

private let maxSizePerRequest = 100

public typealias MultiSaveResultTuple<T> = (entities: AnyRandomAccessCollection<T?>, errors: AnyRandomAccessCollection<Swift.Error>)

internal class SaveMultiOperation<T: Persistable>: WriteOperation<T, MultiSaveResultTuple<T>>, WriteOperationType where T: NSObject {
    
    var persistable: AnyRandomAccessCollection<T>
    
    typealias ResultType = Swift.Result<MultiSaveResultTuple<T>, Swift.Error>
    
    init<C: RandomAccessCollection>(
        persistable: C,
        writePolicy: WritePolicy,
        sync: AnySync? = nil,
        cache: AnyCache<T>? = nil,
        options: Options?
    ) where C.Element == T {
        self.persistable = AnyRandomAccessCollection(persistable)
        super.init(
            writePolicy: writePolicy,
            sync: sync,
            cache: cache,
            options: options
        )
    }
    
    func executeLocal(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = LocalRequest<Swift.Result<MultiSaveResultTuple<T>, Swift.Error>>()
        request.execute { () -> Void in
            let networkRequest = self.client.networkRequestFactory.buildAppDataSave(
                persistable,
                options: options,
                resultType: ResultType.self
            )
            
            if let cache = self.cache {
                cache.save(entities: persistable, syncQuery: nil)
            }
            
            if let sync = self.sync {
                sync.savePendingOperation(sync.createPendingOperation(networkRequest.request))
            }
            request.result = .success((entities: AnyRandomAccessCollection(persistable.map({ Optional($0) })), errors: AnyRandomAccessCollection(EmptyCollection())))
            if let completionHandler = completionHandler, let result = request.result {
                completionHandler(result)
            }
        }
        return AnyRequest(request)
    }
    
    func executeNetwork(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        switch persistable.count {
        case 0:
            let result: Swift.Result<MultiSaveResultTuple<T>, Swift.Error> = .success((entities: AnyRandomAccessCollection(EmptyCollection()), errors: AnyRandomAccessCollection(EmptyCollection())))
            completionHandler?(result)
            return AnyRequest(result)
        case 1 ... maxSizePerRequest:
            return saveSingleRequest(persistable: persistable, completionHandler)
        default:
            return saveMultiRequests(completionHandler)
        }
    }
    
    @discardableResult
    private func saveSingleRequest(persistable: AnyRandomAccessCollection<T>, _ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = client.networkRequestFactory.buildAppDataSave(
            persistable,
            options: options,
            resultType: ResultType.self
        )
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                let result: ResultType
                if let response = response,
                    response.isOK,
                    let data = data,
                    let json = try? self.client.jsonParser.parseDictionary(from: data),
                    let entitiesJson = json["entities"] as? [[String : Any]?],
                    let entities = try? entitiesJson.map({ (item) -> T? in
                        guard let item = item else {
                            return nil
                        }
                        return try self.client.jsonParser.parseObject(T.self, from: item)
                    }),
                    let errors = json["errors"] as? [[String : Any]]
                {
                    for entity in entities {
                        guard let entity = entity else {
                            continue
                        }
                        if let objectId = entity.entityId,
                            let sync = self.sync
                        {
                            sync.removeAllPendingOperations(
                                objectId,
                                methods: ["POST", "PUT"]
                            )
                        }
                        if let cache = self.cache {
                            cache.remove(entity: entity)
                            cache.save(entity: entity)
                        }
                    }
                    result = .success((
                        entities: AnyRandomAccessCollection(entities),
                        errors: AnyRandomAccessCollection(errors.map({
                            let json = $0
                            guard let index = json["index"] as? Int,
                                let code = json["code"] as? Int,
                                let errmsg = json["errmsg"] as? String
                            else {
                                return Error.unknownJsonError(httpResponse: response.httpResponse, data: data, json: json)
                            }
                            return MultiSaveError(
                                index: index,
                                code: code,
                                message: errmsg
                            )
                        }))
                    ))
                } else {
                    result = .failure(buildError(data, response, error, self.client))
                }
                request.result = result
                completionHandler?(result)
            }
        }
        return AnyRequest(request)
    }
    
    private func saveMultiRequests(_ completionHandler: CompletionHandler?) -> AnyRequest<ResultType> {
        let request = MultiRequest<ResultType>()
        var offsetIterator = stride(from: 0, to: persistable.count, by: maxSizePerRequest).makeIterator()
        let promisesIterator = AnyIterator<Promise<MultiSaveResultTuple<T>>> {
            guard let offset = offsetIterator.next() else {
                return nil
            }
            let startIndex = self.persistable.index(self.persistable.startIndex, offsetBy: offset)
            let endIndex = self.persistable.index(self.persistable.startIndex, offsetBy: offset + maxSizePerRequest, limitedBy: self.persistable.endIndex) ?? self.persistable.endIndex
            return Promise<MultiSaveResultTuple> { resolver in
                let range = startIndex ..< endIndex
                let slice = self.persistable[range]
                self.saveSingleRequest(persistable: slice) {
                    switch $0 {
                    case .success(let tuple):
                        resolver.fulfill(tuple)
                    case .failure(let error):
                        resolver.reject(error)
                    }
                }
            }
        }
        let urlSessionConfiguration = options?.urlSession?.configuration ?? client.urlSession.configuration
        when(fulfilled: promisesIterator, concurrently: urlSessionConfiguration.httpMaximumConnectionsPerHost).done(on: DispatchQueue.global(qos: .default)) { results -> Void in
            let result = results.reduce(into: MultiSaveResultTuple(entities: AnyRandomAccessCollection<T?>(EmptyCollection()), errors: AnyRandomAccessCollection<Swift.Error>(EmptyCollection()))) { (result, item) in
                result.entities = AnyRandomAccessCollection(MultipleRandomAccessCollection(result.entities, item.entities))
                result.errors = AnyRandomAccessCollection(MultipleRandomAccessCollection(result.errors, item.errors))
            }
            request.result = .success((entities: result.entities, errors: result.errors))
        }.catch { error in
            request.result = .failure(error)
        }.finally {
            if let completionHandler = completionHandler, let result = request.result {
                completionHandler(result)
            }
        }
        return AnyRequest(request)
    }
    
    fileprivate func checkRequirements(_ completionHandler: CompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(.failure(Error.noActiveUser))
            return false
        }
        
        return true
    }
    
}
