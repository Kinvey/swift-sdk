//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public class Metadata: NSObject {
    
    public let lmt: String
    public let ect: String
    public let authtoken: String?
    
    public init(lmt: String, ect: String, authtoken: String?) {
        self.lmt = lmt
        self.ect = ect
        self.authtoken = authtoken
    }
    
    public convenience init(json: [String : String]) {
        self.init(
            lmt: json["lmt"] as String!,
            ect: json["ect"] as String!,
            authtoken: json["authtoken"] as String?
        )
    }

}
