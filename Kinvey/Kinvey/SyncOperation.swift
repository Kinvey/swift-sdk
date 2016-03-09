//
//  SyncOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVSyncOperation)
public class SyncOperation: WriteOperation {
    
    @objc public override func execute(completionHandler: CompletionHandlerObjC?) -> Request {
        return execute { (objs, error) -> Void in
            completionHandler?(objs, error as? NSError)
        }
    }
    
}
