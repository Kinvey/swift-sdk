//
//  LocalRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

@objc(__KNVLocalRequest)
internal class LocalRequest: NSObject, Request {
    
    let executing = false
    let cancelled = false
    
    typealias LocalHandler = () -> Void
    
    var uploadProgress: ((Int64, Int64) -> Void)?
    var downloadProgress: ((Int64, Int64) -> Void)?
    
    let localHandler: LocalHandler?
    
    init(_ localHandler: LocalHandler? = nil) {
        self.localHandler = localHandler
    }
    
    func execute(@noescape completionHandler: LocalHandler) {
        localHandler?()
        completionHandler()
    }
    
    func cancel() {
        //do nothing
    }

}
