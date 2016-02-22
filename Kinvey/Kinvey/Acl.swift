//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

@objc(KNVAcl)
public class Acl: NSObject {
    
    public static let CreatorKey = "creator"
    
    public let creator: String
    
    public init(creator: String) {
        self.creator = creator
    }
    
    public convenience init(json: [String : AnyObject]) {
        self.init(creator: json[Acl.CreatorKey] as! String)
    }
    
    public func toJson() -> [String : AnyObject] {
        return [
            Acl.CreatorKey : creator
        ]
    }

}
