//
//  Command.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Class to interact with a custom endpoint in the backend.
@objc(KNVCustomEndpoint)
public class CustomEndpoint: NSObject {
    
    /// Completion handler block for execute custom endpoints.
    public typealias CompletionHandler = (JsonDictionary?, ErrorType?) -> Void
    
    /// Executes a custom endpoint by name and passing the expected parameters.
    public static func execute(name: String, params: JsonDictionary? = nil, client: Client = sharedClient, completionHandler: CompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildCustomEndpoint(name)
        if let params = params {
            request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(params.toJson(), options: [])
        }
        request.request.setValue(nil, forHTTPHeaderField: RequestIdHeaderKey)
        request.execute() { data, response, error in
            if let completionHandler = dispatchAsyncMainQueue(completionHandler) {
                if let response = response where response.isOK, let json = client.responseParser.parse(data) {
                    completionHandler(json, nil)
                } else if let error = error {
                    completionHandler(nil, error)
                } else {
                    completionHandler(nil, Error.InvalidResponse)
                }
            }
        }
        return request
    }
    
    //MARK: Dispatch Async Main Queue
    
    private static func dispatchAsyncMainQueue<R>(completionHandler: ((R?, ErrorType?) -> Void)? = nil) -> ((JsonDictionary?, ErrorType?) -> Void)? {
        if let completionHandler = completionHandler {
            return { (obj, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    completionHandler(obj as? R, error)
                })
            }
        }
        return nil
    }
}
