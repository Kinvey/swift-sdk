//
//  KinveyURLProtocol.swift
//  KinveyTests
//
//  Created by Victor Hugo Carvalho Barros on 2019-04-16.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation
import XCTest

class KinveyURLProtocolClient: NSObject, URLProtocolClient {
    
    var response: URLResponse?
    var data: Data?
    var error: Error?
    
    func urlProtocol(_ protocol: URLProtocol, wasRedirectedTo request: URLRequest, redirectResponse: URLResponse) {
    }
    
    func urlProtocol(_ protocol: URLProtocol, cachedResponseIsValid cachedResponse: CachedURLResponse) {
    }
    
    func urlProtocol(_ protocol: URLProtocol, didReceive response: URLResponse, cacheStoragePolicy policy: URLCache.StoragePolicy) {
        self.response = response
    }
    
    func urlProtocol(_ protocol: URLProtocol, didLoad data: Data) {
        self.data = data
    }
    
    func urlProtocolDidFinishLoading(_ protocol: URLProtocol) {
    }
    
    func urlProtocol(_ protocol: URLProtocol, didFailWithError error: Error) {
        self.error = error
    }
    
    func urlProtocol(_ protocol: URLProtocol, didReceive challenge: URLAuthenticationChallenge) {
    }
    
    func urlProtocol(_ protocol: URLProtocol, didCancel challenge: URLAuthenticationChallenge) {
    }
    
}

class KinveyURLProtocol: URLProtocol {
    
    static var appKey = "kid_\(UUID().uuidString)"
    static var appSecret = UUID().uuidString
    
    private static var users = [
        String : [ //_id
            String : Any
        ]
    ]()
    
    private static var userSessions = [String : String]()
    
    private static var collections = [
        String : [ //collection
            String : [ //_id
                String : Any
            ]
        ]
    ]()
    
    private static var blob = [String : [String : Any]]()
    private static var blobData = [String : Data]()
    
    class func reset() {
        users.removeAll()
        userSessions.removeAll()
        collections.removeAll()
        blob.removeAll()
        blobData.removeAll()
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return false
        }
        return urlComponents.scheme == "https" && urlComponents.host == "baas.kinvey.com"
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url,
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return
        }
        let httpMethod = request.httpMethod ?? "GET"
        switch (httpMethod, urlComponents.path) {
        case ("POST", "/user/\(KinveyURLProtocol.appKey)/login"):
            let json = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
            let users = KinveyURLProtocol.users.filter { key, user in
                return user["username"] as? String == json["username"] as? String &&
                    user["password"] as? String == json["password"] as? String
            }
            switch users.count {
            case 1:
                sendResponse(url: url, body: .jsonObject(users.first!.value))
            default:
                sendResponse(
                    url: url,
                    statusCode: 401,
                    body: .jsonObject([
                        "error" : "InvalidCredentials",
                        "description" : "Invalid credentials. Please retry your request with correct credentials.",
                        "debug" : ""
                    ])
                )
            }
        case ("POST", "/user/\(KinveyURLProtocol.appKey)/_logout"):
            guard let authtoken = validateUserAuth(url: url) else {
                return
            }
            KinveyURLProtocol.userSessions.removeValue(forKey: authtoken)
            sendResponse(url: url, statusCode: 204)
        case ("POST", "/user/\(KinveyURLProtocol.appKey)"):
            var json = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
            if json["_id"] == nil {
                json["_id"] = UUID().uuidString
            }
            let id = json["_id"] as! String
            var kmd = [String : Any]()
            kmd["ltm"] = Date().toISO8601()
            kmd["ect"] = Date().toISO8601()
            let authtoken = UUID().uuidString
            kmd["authtoken"] = authtoken
            json["_kmd"] = kmd
            KinveyURLProtocol.users[id] = json
            KinveyURLProtocol.userSessions[authtoken] = id
            sendResponse(url: url, statusCode: 201, body: .jsonObject(json))
        default:
            let regexAppData = try! NSRegularExpression(pattern: "\\/appdata\\/\(KinveyURLProtocol.appKey)\\/([^/]*)\\/?([^/]*)")
            let regexBlob = try! NSRegularExpression(pattern: "\\/blob\\/\(KinveyURLProtocol.appKey)\\/([^/]*)\\/?([^/]*)")
            if let match = regexAppData.firstMatch(in: urlComponents.path, range: NSRange(location: 0, length: urlComponents.path.count)),
                match.numberOfRanges == 3
            {
                guard let authtoken = validateUserAuth(url: url), KinveyURLProtocol.userSessions[authtoken] != nil else {
                    return
                }
                
                var range = match.range(at: 1)
                var startIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.lowerBound)
                var endIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.upperBound)
                let collection = String(urlComponents.path[startIndex ..< endIndex])
                
                if KinveyURLProtocol.collections[collection] == nil {
                    KinveyURLProtocol.collections[collection] = [:]
                }
                
                range = match.range(at: 2)
                startIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.lowerBound)
                endIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.upperBound)
                let id = String(urlComponents.path[startIndex ..< endIndex])
                
                let now = Date().toISO8601()
                
                switch httpMethod {
                case "POST":
                    let json = try! JSONSerialization.jsonObject(with: request)
                    let kinveyApiVersion = request.allHTTPHeaderFields?["X-Kinvey-API-Version"]
                    if var json = json as? [String : Any] {
                        if json["_id"] == nil {
                            json["_id"] = UUID().uuidString
                        }
                        let id = json["_id"] as! String
                        var kmd = [String : Any]()
                        kmd["lmt"] = now
                        kmd["ect"] = now
                        json["_kmd"] = kmd
                        KinveyURLProtocol.collections[collection]![id] = json
                        sendResponse(url: url, statusCode: 201, body: .jsonObject(json))
                    } else if var jsonArray = json as? [[String : Any]] {
                        guard let kinveyApiVersion = kinveyApiVersion, kinveyApiVersion == "5" else {
                            sendResponse(url: url, statusCode: 400, body: .jsonObject([
                                "error": "FeatureUnavailable",
                                "description": "Requested functionality is unavailable in this API version.",
                                "debug": "Inserting multiple entities is not available in this Kinvey API version"
                            ]))
                            return
                        }
                        jsonArray = jsonArray.map { json in
                            var json = json
                            if json["_id"] == nil {
                                json["_id"] = UUID().uuidString
                            }
                            let id = json["_id"] as! String
                            var kmd = [String : Any]()
                            kmd["lmt"] = now
                            kmd["ect"] = now
                            json["_kmd"] = kmd
                            KinveyURLProtocol.collections[collection]![id] = json
                            return json
                        }
                        sendResponse(
                            url: url,
                            statusCode: 201,
                            body: .jsonObject([
                                "entities": jsonArray,
                                "errors": []
                            ])
                        )
                    } else {
                        sendResponseEntityNotFound(url: url)
                    }
                case "PUT":
                    var json = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
                    var kmd = KinveyURLProtocol.collections[collection]![id]?["_kmd"] as? [String : Any] ?? [:]
                    if kmd["ect"] == nil {
                        kmd["ect"] = now
                    }
                    kmd["lmt"] = now
                    json["_kmd"] = kmd
                    KinveyURLProtocol.collections[collection]![id] = json
                    sendResponse(url: url, statusCode: 200, body: .jsonObject(json))
                case "DELETE":
                    switch id {
                    case "":
                        let results = find(collection: collection, urlComponents: urlComponents)
                        var removed = 0
                        for item in results {
                            if KinveyURLProtocol.collections[collection]!.removeValue(forKey: item["_id"] as! String) != nil {
                                removed += 1
                            }
                        }
                        sendResponse(url: url, statusCode: 200, body: .jsonObject(["count" : removed]))
                    default:
                        if KinveyURLProtocol.collections[collection]!.removeValue(forKey: id) != nil {
                            sendResponse(url: url, statusCode: 200, body: .jsonObject(["count" : 1]))
                        } else {
                            sendResponseEntityNotFound(url: url)
                        }
                    }
                default:
                    switch id {
                    case "":
                        let results = find(collection: collection, urlComponents: urlComponents)
                        sendResponse(url: url, body: .jsonArray(results))
                    case "_count":
                        let results = find(collection: collection, urlComponents: urlComponents)
                        sendResponse(url: url, body: .jsonObject(["count" : results.count]))
                    case "_deltaset":
                        if let queryItems = urlComponents.queryItems,
                            let since = queryItems.first(where: { $0.name == "since" })?.value
                        {
                            let changed = find(collection: collection).filter {
                                let kmd = $0["_kmd"] as! [String : Any]
                                let lmt = kmd["lmt"] as! String
                                return lmt > since
                            }
                            sendResponse(
                                url: url,
                                body: .jsonObject([
                                    "changed" : changed,
                                    "deleted" : []
                                ])
                            )
                        } else {
                            fallthrough
                        }
                    default:
                        if let result = KinveyURLProtocol.collections[collection]![id] {
                            sendResponse(url: url, body: .jsonObject(result))
                        } else {
                            sendResponseEntityNotFound(url: url)
                        }
                    }
                }
            } else if let match = regexBlob.firstMatch(in: urlComponents.path, range: NSRange(location: 0, length: urlComponents.path.count)),
                match.numberOfRanges >= 2
            {
                var range = match.range(at: 1)
                var startIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.lowerBound)
                var endIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.upperBound)
                var id = String(urlComponents.path[startIndex ..< endIndex])
                
                range = match.range(at: 2)
                startIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.lowerBound)
                endIndex = urlComponents.path.index(urlComponents.path.startIndex, offsetBy: range.upperBound)
                let lastUrlComponent = String(urlComponents.path[startIndex ..< endIndex])
                
                let now = Date()
                
                switch httpMethod {
                case "PUT":
                    switch lastUrlComponent {
                    case "upload":
                        KinveyURLProtocol.blobData[id] = request.httpBodyData
                        sendResponse(
                            url: url,
                            statusCode: 200,
                            body: .data("".data(using: .utf8)!)
                        )
                    default:
                        if id.isEmpty {
                            id = UUID().uuidString
                        }
                        var json = try! JSONSerialization.jsonObject(with: request) as! [String : Any]
                        if json["_id"] == nil || json["_id"] as? String != id {
                            json["_id"] = id
                        }
                        if json["_filename"] == nil {
                            json["_filename"] = UUID().uuidString
                        }
                        json["_acl"] = [
                            "creator": validateUserAuth(url: url)!
                        ]
                        json["_kmd"] = [
                            "lmt": now.toISO8601(),
                            "ect": now.toISO8601()
                        ]
                        json["_uploadURL"] = "https://baas.kinvey.com/blob/\(KinveyURLProtocol.appKey)/\(id)/upload"
                        json["_downloadURL"] = "https://baas.kinvey.com/blob/\(KinveyURLProtocol.appKey)/\(id)/download"
                        json["_expiresAt"] = now.addingTimeInterval(30).toISO8601()
                        json["_requiredHeaders"] = [:]
                        KinveyURLProtocol.blob[id] = json
                        sendResponse(
                            url: url,
                            statusCode: 201,
                            body: .jsonObject(json)
                        )
                    }
                default:
                    if id.isEmpty {
                        let metadatas = Array(KinveyURLProtocol.blob.values)
                        sendResponse(
                            url: url,
                            statusCode: 200,
                            body: .jsonArray(metadatas)
                        )
                    } else {
                        switch lastUrlComponent {
                        case "download":
                            if let data = KinveyURLProtocol.blobData[id] {
                                sendResponse(
                                    url: url,
                                    statusCode: 200,
                                    body: .data(data)
                                )
                            } else {
                                sendResponse(
                                    url: url,
                                    statusCode: 404,
                                    body: .jsonObject([
                                        "error": "BlobNotFound",
                                        "description": "This blob not found for this app backend.",
                                        "debug": ""
                                    ])
                                )
                            }
                        default:
                            if let metadata = KinveyURLProtocol.blob[id] {
                                sendResponse(
                                    url: url,
                                    statusCode: 200,
                                    body: .jsonObject(metadata)
                                )
                            } else {
                                sendResponse(
                                    url: url,
                                    statusCode: 404,
                                    body: .jsonObject([
                                        "error": "BlobNotFound",
                                        "description": "This blob not found for this app backend.",
                                        "debug": ""
                                        ])
                                )
                            }
                        }
                    }
                }
            } else {
                sendResponse(url: url, statusCode: 404)
                XCTFail("HTTP Method: \(httpMethod) Path: \(urlComponents.path) not handled")
            }
        }
    }
    
    override func stopLoading() {
    }
    
    enum Body {
        case data(Data)
        case jsonObject([String : Any])
        case jsonArray([[String : Any]])
    }
    
    private func find(collection: String) -> [[String : Any]] {
        var results = KinveyURLProtocol.collections[collection]!.map { $1 }
        results.sort { (obj1, obj2) -> Bool in
            let kmd1 = obj1["_kmd"] as! [String : Any]
            let kmd2 = obj2["_kmd"] as! [String : Any]
            let ect1 = kmd1["ect"] as! String
            let ect2 = kmd2["ect"] as! String
            return ect1 < ect2
        }
        return results
    }
    
    private func find(collection: String, urlComponents: URLComponents) -> [[String : Any]] {
        var results = find(collection: collection)
        if let queryItems = urlComponents.queryItems {
            if let queryItem = queryItems.first(where: { $0.name == "query" }),
                let queryString = queryItem.value,
                let data = queryString.data(using: .utf8),
                let query = try? JSONSerialization.jsonObject(with: data) as? [String : Any]
            {
                for (key, value) in query {
                    results = results.filter {
                        switch value {
                        case let operatorValue as [String : Any]:
                            for (op, value) in operatorValue {
                                switch op {
                                case "$lt":
                                    switch ($0[key], value) {
                                    case let (value1, value2) as (Int, Int):
                                        return value1 < value2
                                    default:
                                        return false
                                    }
                                case "$lte":
                                    switch ($0[key], value) {
                                    case let (value1, value2) as (Int, Int):
                                        return value1 <= value2
                                    default:
                                        return false
                                    }
                                case "$gt":
                                    switch ($0[key], value) {
                                    case let (value1, value2) as (Int, Int):
                                        return value1 > value2
                                    default:
                                        return false
                                    }
                                case "$gte":
                                    switch ($0[key], value) {
                                    case let (value1, value2) as (Int, Int):
                                        return value1 >= value2
                                    default:
                                        return false
                                    }
                                default:
                                    return false
                                }
                            }
                        case let intValue as Int:
                            switch ($0[key], intValue) {
                            case let (intValue1, intValue2) as (Int, Int):
                                return intValue1 == intValue2
                            default:
                                return false
                            }
                        default:
                            return false
                        }
                        return false
                    }
                }
            }
            if let queryItem = queryItems.first(where: { $0.name == "sort" }),
                let sortString = queryItem.value,
                let data = sortString.data(using: .utf8),
                let sort = try? JSONSerialization.jsonObject(with: data) as? [String : Int]
            {
                for (key, value) in sort {
                    results.sort { (obj1, obj2) -> Bool in
                        switch (obj1[key], obj2[key]) {
                        case let (value1, value2) as (Int, Int):
                            if value == -1 {
                                return value1 > value2
                            } else {
                                return value1 < value2
                            }
                        default:
                            return false
                        }
                    }
                }
            }
            if let queryItem = queryItems.first(where: { $0.name == "skip" }),
                let skipString = queryItem.value,
                let skip = Int(skipString)
            {
                results = Array(results[skip...])
            }
            if let queryItem = queryItems.first(where: { $0.name == "limit" }),
                let limitString = queryItem.value,
                let limit = Int(limitString)
            {
                results = Array(results[0 ..< limit])
            }
        }
        return results
    }
    
    private func sendResponseEntityNotFound(url: URL) {
        sendResponse(
            url: url,
            statusCode: 404,
            body: .jsonObject([
                "error" : "EntityNotFound",
                "description" : "This entity not found in the collection.",
                "debug" : ""
            ])
        )
    }
    
    private func sendResponse(
        url: URL,
        statusCode: Int = 200,
        httpVersion: String? = nil,
        headerFields: [String : String]? = nil,
        cacheStoragePolicy: URLCache.StoragePolicy = .notAllowed,
        body: Body? = nil
    ) {
        var headerFields = headerFields ?? [:]
        headerFields["x-kinvey-request-start"] = Date().toISO8601()
        client!.urlProtocol(
            self,
            didReceive: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)!,
            cacheStoragePolicy: cacheStoragePolicy
        )
        if let body = body {
            switch body {
            case .jsonObject(let jsonObject):
                let data = try! JSONSerialization.data(withJSONObject: jsonObject)
                client!.urlProtocol(self, didLoad: data)
            case .jsonArray(let jsonArray):
                let data = try! JSONSerialization.data(withJSONObject: jsonArray)
                client!.urlProtocol(self, didLoad: data)
            case .data(let data):
                client!.urlProtocol(self, didLoad: data)
            }
        }
        client!.urlProtocolDidFinishLoading(self)
    }
    
    private func validateUserAuth(url: URL) -> String? {
        guard let authorization = request.allHTTPHeaderFields?["Authorization"],
            let regex = try? NSRegularExpression(pattern: "Kinvey (.*)"),
            let match = regex.firstMatch(in: authorization, range: NSRange(location: 0, length: authorization.count)),
            match.numberOfRanges == 2
        else {
            sendResponse(
                url: url,
                statusCode: 403,
                body: .jsonObject([
                    "error" : "InvalidCredentials",
                    "description" : "Invalid credentials. Please retry your request with correct credentials.",
                    "debug" : ""
                ])
            )
            return nil
        }
        let range = match.range(at: 1)
        let startIndex = authorization.index(authorization.startIndex, offsetBy: range.lowerBound)
        let endIndex = authorization.index(authorization.startIndex, offsetBy: range.upperBound)
        let authtoken = String(authorization[startIndex ..< endIndex])
        return authtoken
    }
    
}
