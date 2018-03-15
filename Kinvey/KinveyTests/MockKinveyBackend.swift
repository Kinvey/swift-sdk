//
//  MockKinveyBackend.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey
import Foundation

class MockKinveyBackend: URLProtocol {
    
    static var kid = "_kid_"
    static var baseURLBaas = URL(string: "https://baas.kinvey.com")!
    static var user = [String : [String : Any]]()
    static var appdata = [String : [[String : Any]]]()
    static var usersMustIncludeSocialIdentity: Bool = false
    
    var requestJsonBody: [String : Any]? {
        if
            let httpBody = request.httpBody,
            let obj = try? JSONSerialization.jsonObject(with: httpBody),
            let json = obj as? [String : Any]
        {
            return json
        } else if let httpBodyStream = request.httpBodyStream {
            httpBodyStream.open()
            defer {
                httpBodyStream.close()
            }
            let object = try? JSONSerialization.jsonObject(with: httpBodyStream)
            return object as? [String : Any]
        } else {
            return nil
        }
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        return request.url!.scheme == MockKinveyBackend.baseURLBaas.scheme && request.url!.host == MockKinveyBackend.baseURLBaas.host
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        let requestJsonBody = self.requestJsonBody
        if let pathComponents = request.url?.pathComponents {
            if pathComponents.count > 3 {
                if pathComponents[1] == "appdata" && pathComponents[2] == MockKinveyBackend.kid, let collection = MockKinveyBackend.appdata[pathComponents[3]] {
                    let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                    client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                    
                    var array: [[String : Any]]
                    if let query = request.url?.query {
                        var queryParams = [String : String]()
                        let queryComponents = query.components(separatedBy: "&")
                        for queryComponent in queryComponents {
                            let keyValuePair = queryComponent.components(separatedBy: "=")
                            queryParams[keyValuePair[0]] = keyValuePair[1]
                        }
                        if let queryParamStr = queryParams["query"]?.removingPercentEncoding,
                            let data = queryParamStr.data(using: String.Encoding.utf8),
                            let json = try? JSONSerialization.jsonObject(with: data),
                            let query = json as? [String : Any]
                        {
                            array = collection.filter({ (entity) -> Bool in
                                for keyValuePair in query {
                                    if let value = entity[keyValuePair.0] as? String,
                                        let matchValue = keyValuePair.1 as? String,
                                        value != matchValue
                                    {
                                        return false
                                    }
                                }
                                return true
                            })
                        } else {
                            array = collection
                        }
                    } else {
                        array = collection
                    }
                    let data = try! JSONSerialization.data(withJSONObject: array)
                    client?.urlProtocol(self, didLoad: data)
                    
                    client?.urlProtocolDidFinishLoading(self)
                } else if pathComponents[1] == "user" && pathComponents[2] == MockKinveyBackend.kid {
                    let userId = pathComponents[3]
                    if let httpMethod = request.httpMethod {
                        switch httpMethod {
                        case "PUT":
                            if let requestJsonBody = requestJsonBody, var user = MockKinveyBackend.user[userId] {
                                user += requestJsonBody
                                MockKinveyBackend.user[userId] = user
                                
                                response(json: user)
                            } else {
                                reponse404()
                            }
                        case "DELETE":
                            if var _ = MockKinveyBackend.user[userId] {
                                MockKinveyBackend.user[userId] = nil
                                response204()
                            } else {
                                reponse404()
                            }
                        default:
                            reponse404()
                        }
                    }
                } else {
                    reponse404()
                }
            } else if pathComponents.count > 2 {
                if pathComponents[1] == "user" && pathComponents[2] == MockKinveyBackend.kid {
                    if let httpMethod = request.httpMethod {
                        switch httpMethod {
                        case "POST":
                            let userId = (requestJsonBody?["_id"] as? String) ?? UUID().uuidString
                            if var user = requestJsonBody {
                                user["_id"] = userId
                                if user["username"] == nil {
                                    user["username"] = UUID().uuidString
                                }
                                user["_kmd"] = [
                                    "lmt" : "2016-10-19T21:06:17.367Z",
                                    "ect" : "2016-10-19T21:06:17.367Z",
                                    "authtoken" : UUID().uuidString
                                ]
                                user["_acl"] = [
                                    "creator" : "masterKey-creator-id"
                                ]
                                if MockKinveyBackend.usersMustIncludeSocialIdentity {
                                    user["_socialIdentity"] = [
                                        "kinveyAuth" : [
                                            "access_token" : UUID().uuidString,
                                            "token_type" : "Bearer",
                                            "expires_in" : 59,
                                            "refresh_token" : UUID().uuidString
                                        ]
                                    ]
                                }
                                MockKinveyBackend.user[userId] = user
                                
                                response(json: user)
                            }
                        default:
                            reponse404()
                        }
                    } else {
                        reponse404()
                    }
                } else {
                    reponse404()
                }
            } else {
                reponse404()
            }
        } else {
            reponse404()
        }
    }
    
    override func stopLoading() {
    }
    
    //Not Found
    private func reponse404() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    //No Content
    private func response204() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    private func response(json: [String : Any]) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        let data = try! JSONSerialization.data(withJSONObject: json)
        client?.urlProtocol(self, didLoad: data)
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
}
