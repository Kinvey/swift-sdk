//
//  LocalRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal class LocalRequest<Result>: NSObject, Request {
    
    typealias ResultType = Result
    
    internal var result: Result?
    
    let executing = false
    let cancelled = false
    
    typealias LocalHandler = () -> Void
    
    var progress = Progress()
    
    let localHandler: LocalHandler?
    
    init(_ localHandler: LocalHandler? = nil) {
        self.localHandler = localHandler
    }
    
    func execute(_ completionHandler: LocalHandler) {
        localHandler?()
        completionHandler()
    }
    
    func cancel() {
        //do nothing
    }
    
    convenience init(_ result: ResultType) {
        self.init()
        self.result = result
    }

}
