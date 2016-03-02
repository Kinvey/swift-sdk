//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

@objc(KNVMetadata)
public class Metadata: NSObject {
    
    public static let LmtKey = "lmt"
    public static let EctKey = "ect"
    public static let AuthTokenKey = "authtoken"
    
    public let lmt: NSDate?
    public let ect: NSDate?
    
    public internal(set) var authtoken: String?
    
    public init(lmt: NSDate? = nil, ect: NSDate? = nil, authtoken: String? = nil) {
        self.lmt = lmt
        self.ect = ect
        self.authtoken = authtoken
    }
    
    public convenience init(json: [String : AnyObject]) {
        self.init(
            lmt: (json[Metadata.LmtKey] as? String)?.toDate(),
            ect: (json[Metadata.EctKey] as? String)?.toDate(),
            authtoken: json[Metadata.AuthTokenKey] as? String
        )
    }
    
    public func toJson() -> [String : AnyObject] {
        var json: [String : AnyObject] = [:]
        if let lmt = lmt {
            json[Metadata.LmtKey] = lmt
        }
        if let ect = ect {
            json[Metadata.EctKey] = ect
        }
        if let authtoken = authtoken {
            json[Metadata.AuthTokenKey] = authtoken
        }
        return json
    }

}
