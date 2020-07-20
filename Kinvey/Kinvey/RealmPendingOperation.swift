//
//  RealmPendingOperation.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

internal class RealmPendingOperation: Object, PendingOperation {

    @objc
    dynamic var requestId: String = ""

    @objc
    dynamic var date: Date = Date()

    @objc
    dynamic var collectionName: String = ""

    @objc
    dynamic var objectId: String?

    var objectIds: AnyRandomAccessCollection<String>?
    var requestIds: AnyRandomAccessCollection<String>?

    @objc
    dynamic var method: String = ""

    @objc
    dynamic var url: String = ""

    @objc
    dynamic var headers: Data = Data()

    @objc
    dynamic var body: Data?

    convenience init<RequestIds>(
        request: URLRequest,
        collectionName: String,
        objectIdKind: ObjectIdKind? = nil,
        requestIds: RequestIds
    ) where RequestIds: RandomAccessCollection, RequestIds.Element == String {
        self.init(
            request: request,
            collectionName: collectionName,
            objectIdKind: objectIdKind
        )
        self.requestIds = AnyRandomAccessCollection(requestIds)
    }

    convenience init(
        request: URLRequest,
        collectionName: String,
        objectIdKind: ObjectIdKind? = nil
    ) {
        self.init()

        requestId = request.value(forHTTPHeaderField: KinveyHeaderField.requestId)!
        self.collectionName = collectionName
        if let objectIdKind = objectIdKind {
            switch objectIdKind {
            case .objectId(let objectId):
                self.objectId = objectId
            case .objectIds(let objectIds):
                self.objectIds = objectIds
            }
        }
        method = request.httpMethod ?? "GET"
        url = request.url!.absoluteString
        headers = try! JSONSerialize.data(request.allHTTPHeaderFields!)
        body = request.httpBody
    }

    func buildRequest() -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        request.allHTTPHeaderFields = try? JSONSerialization.jsonObject(with: headers) as? [String : String]
        if let body = body {
            request.httpBody = body
        }
        return request
    }

    override class func primaryKey() -> String? {
        return "requestId"
    }

}
