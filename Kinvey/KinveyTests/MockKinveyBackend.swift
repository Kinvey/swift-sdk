//
//  MockKinveyBackend.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
@testable import Kinvey

class MockKinveyBackend: NSURLProtocol {
    
    static var kid = "_kid_"
    static var baseURLBaas = NSURL(string: "https://baas.kinvey.com")!
    static var user = [String : [String : AnyObject]]()
    static var appdata = [String : [[String : AnyObject]]]()
    
    var requestJsonBody: [String : AnyObject]? {
        if
            let httpBody = request.HTTPBody,
            let obj = try? NSJSONSerialization.JSONObjectWithData(httpBody, options: []),
            let json = obj as? [String : AnyObject]
        {
            return json
        } else if let httpBodyStream = request.HTTPBodyStream {
            httpBodyStream.open()
            defer {
                httpBodyStream.close()
            }
            return (try? NSJSONSerialization.JSONObjectWithStream(httpBodyStream, options: [])) as? [String : AnyObject]
        } else {
            return nil
        }
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL!.scheme == MockKinveyBackend.baseURLBaas.scheme && request.URL!.host == MockKinveyBackend.baseURLBaas.host
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override func startLoading() {
        let requestJsonBody = self.requestJsonBody
        if let pathComponents = request.URL?.pathComponents {
            if pathComponents.count > 3 {
                if pathComponents[1] == "appdata" && pathComponents[2] == MockKinveyBackend.kid, let collection = MockKinveyBackend.appdata[pathComponents[3]] {
                    let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
                    client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
                    
                    var array: [[String : AnyObject]]
                    if let query = request.URL?.query {
                        var queryParams = [String : String]()
                        let queryComponents = query.componentsSeparatedByString("&")
                        for queryComponent in queryComponents {
                            let keyValuePair = queryComponent.componentsSeparatedByString("=")
                            queryParams[keyValuePair[0]] = keyValuePair[1]
                        }
                        if let queryParamStr = queryParams["query"]?.stringByRemovingPercentEncoding,
                            let data = queryParamStr.dataUsingEncoding(NSUTF8StringEncoding),
                            let json = try? NSJSONSerialization.JSONObjectWithData(data, options: []),
                            let query = json as? [String : AnyObject]
                        {
                            array = collection.filter({ (entity) -> Bool in
                                for keyValuePair in query {
                                    if let value = entity[keyValuePair.0] as? String,
                                        let matchValue = keyValuePair.1 as? String
                                        where value != matchValue
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
                    let data = try! NSJSONSerialization.dataWithJSONObject(array, options: [])
                    client?.URLProtocol(self, didLoadData: data)
                    
                    client?.URLProtocolDidFinishLoading(self)
                } else if pathComponents[1] == "user" && pathComponents[2] == MockKinveyBackend.kid {
                    let userId = pathComponents[3]
                    if let httpMethod = request.HTTPMethod {
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
                    if let httpMethod = request.HTTPMethod {
                        switch httpMethod {
                        case "POST":
                            let userId = (requestJsonBody?["_id"] as? String) ?? NSUUID().UUIDString
                            if var user = requestJsonBody {
                                user["_id"] = userId
                                if user["username"] == nil {
                                    user["username"] = NSUUID().UUIDString
                                }
                                user["_kmd"] = [
                                    "lmt" : "2016-10-19T21:06:17.367Z",
                                    "ect" : "2016-10-19T21:06:17.367Z",
                                    "authtoken" : NSUUID().UUIDString
                                ]
                                user["_acl"] = [
                                    "creator" : "masterKey-creator-id"
                                ]
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
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 404, HTTPVersion: nil, headerFields: nil)!
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        client?.URLProtocolDidFinishLoading(self)
    }
    
    //No Content
    private func response204() {
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 204, HTTPVersion: nil, headerFields: nil)!
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        client?.URLProtocolDidFinishLoading(self)
    }
    
    private func response(json json: [String : AnyObject]) {
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 200, HTTPVersion: nil, headerFields: nil)!
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        
        let data = try! NSJSONSerialization.dataWithJSONObject(json, options: [])
        client?.URLProtocol(self, didLoadData: data)
        
        client?.URLProtocolDidFinishLoading(self)
    }
    
}
