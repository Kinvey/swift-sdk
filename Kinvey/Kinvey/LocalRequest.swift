//
//  LocalRequest.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit

class LocalRequest: Request {
    
    let executing = false
    let canceled = false
    
    typealias LocalHandler = () -> Void
    
    let localHandler: LocalHandler?
    
    init(_ localHandler: LocalHandler? = nil) {
        self.localHandler = localHandler
    }
    
    func execute(completionHandler: DataResponseCompletionHandler? = nil) {
        localHandler?()
        completionHandler?(nil, LocalResponse(), nil)
    }
    
    func cancel() {
    }

}
