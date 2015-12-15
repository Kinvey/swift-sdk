//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Metadata: NSObject, JsonObject {
    
    private static let LmtKey = "lmt"
    private static let EctKey = "ect"
    private static let AuthTokenKey = "authtoken"
    
    public let lmt: String?
    public let ect: String?
    public let authtoken: String?
    
    public init(lmt: String? = nil, ect: String? = nil, authtoken: String? = nil) {
        self.lmt = lmt
        self.ect = ect
        self.authtoken = authtoken
    }
    
    public convenience init(json: [String : String]) {
        self.init(
            lmt: json[Metadata.LmtKey] as String!,
            ect: json[Metadata.EctKey] as String!,
            authtoken: json[Metadata.AuthTokenKey] as String?
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
