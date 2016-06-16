//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

/// This class represents the metadata information for a record
public class Metadata: NSObject, Mappable {
    
    /// Last Modification Time Key.
    public static let LmtKey = "lmt"
    
    /// Entity Creation Time Key.
    public static let EctKey = "ect"
    
    /// Authentication Token Key.
    public static let AuthTokenKey = "authtoken"
    
    private let lmtString: String?
    private let ectString: String?
    
    /// Last Modification Time.
    public lazy var lmt: NSDate? = self.lmtString?.toDate()
    
    /// Entity Creation Time.
    public lazy var ect: NSDate? = self.ectString?.toDate()
    
    /// Authentication Token.
    public internal(set) var authtoken: String?
    
    /// Default Constructor
    public init(lmt: String? = nil, ect: String? = nil, authtoken: String? = nil) {
        self.lmtString = lmt
        self.ectString = ect
        self.authtoken = authtoken
    }
    
    public required convenience init?(_ map: Map) {
        var lmt: String?
        var ect: String?
        var authtoken: String?
        lmt <- map[Metadata.LmtKey]
        ect <- map[Metadata.EctKey]
        authtoken <- map[Metadata.AuthTokenKey]
        self.init(
            lmt: lmt,
            ect: ect,
            authtoken: authtoken
        )
    }
    
    public func mapping(map: Map) {
        lmt <- map[Metadata.LmtKey]
        ect <- map[Metadata.EctKey]
        authtoken <- map[Metadata.AuthTokenKey]
    }

}
