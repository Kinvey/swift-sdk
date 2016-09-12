//
//  MockKinveyBackend.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-08-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

class MockKinveyBackend: NSURLProtocol {
    
    static var kid = "_kid_"
    static var baseURLBaas = NSURL(string: "https://baas.kinvey.com")!
    static var appdata = [String : [[String : AnyObject]]]()
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        return request.URL!.scheme == MockKinveyBackend.baseURLBaas.scheme && request.URL!.host == MockKinveyBackend.baseURLBaas.host
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override func startLoading() {
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
    
    private func reponse404() {
        let response = NSHTTPURLResponse(URL: request.URL!, statusCode: 404, HTTPVersion: nil, headerFields: nil)!
        client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        client?.URLProtocolDidFinishLoading(self)
    }
    
}
