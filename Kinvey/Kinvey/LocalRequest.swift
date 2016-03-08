//
//  LocalRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit

@objc(__KNVLocalRequest)
public class LocalRequest: NSObject, Request {
    
    public let executing = false
    public let canceled = false
    
    typealias LocalHandler = () -> Void
    
    let localHandler: LocalHandler?
    
    init(_ localHandler: LocalHandler? = nil) {
        self.localHandler = localHandler
    }
    
    func execute(completionHandler: LocalHandler? = nil) {
        localHandler?()
        completionHandler?()
    }
    
    public func cancel() {
        //do nothing
    }

}
