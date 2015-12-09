//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Acl: NSObject {
    
    public let creator: String
    
    public init(creator: String) {
        self.creator = creator
    }
    
    public convenience init(json: [String : String]) {
        self.init(creator: json["creator"] as String!)
    }

}
