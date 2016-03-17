//
//  CommandOperation.swift
//  Kinvey
//
//  Created by Thomas Conner on 3/15/16.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public class CommandOperation : Operation {
    
    typealias CompletionHandler = (AnyObject?, ErrorType?) -> Void
    let persistable: Persistable
    
    public init(persistable: Persistable, client: Client) {
        self.persistable = persistable
        super.init(persistableType: persistable.dynamicType, client: client)
    }
    
    func execute(completionHandler: CompletionHandler?) -> Request {
        return executeNetwork(completionHandler)
    }
    
    func executeNetwork(completionHandler: CompletionHandler?) -> Request {
        let request = client.networkRequestFactory.buildAppDataSave(persistable)
        if checkRequirements(completionHandler) {
            request.execute() { data, response, error in
                if let response = response where response.isResponseOK {
                    let json = self.client.responseParser.parse(data)
                    if let json = json {
                        let persistable = self.persistable.dynamicType.fromJson(json)
                        var persistableJson = self.merge(persistable, json: json)
                        if var kmd = persistableJson[PersistableMetadataKey] as? [String : AnyObject] where kmd[PersistableMetadataLastRetrievedTimeKey] == nil {
                            kmd[PersistableMetadataLastRetrievedTimeKey] = NSDate()
                            persistableJson[PersistableMetadataKey] = kmd
                        }
                        self.persistable.merge(persistable)
                    }
                    completionHandler?(self.persistable, nil)
                } else if let error = error {
                    completionHandler?(nil, error)
                } else {
                    completionHandler?(nil, Error.InvalidResponse)
                }
            }
        }
        return request
    }
    
    private func checkRequirements(completionHandler: ObjectCompletionHandler?) -> Bool {
        guard let _ = client.activeUser else {
            completionHandler?(nil, Error.NoActiveUser)
            return false
        }
        
        return true
    }
}