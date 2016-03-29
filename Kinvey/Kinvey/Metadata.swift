//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

/// This class represents the metadata information for a record
@objc(KNVMetadata)
public class Metadata: NSObject {
    
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
    
    /// Constructor used to build a new `Metadata` instance from a JSON object.
    public convenience init(json: JsonDictionary) {
        self.init(
            lmt: json[Metadata.LmtKey] as? String,
            ect: json[Metadata.EctKey] as? String,
            authtoken: json[Metadata.AuthTokenKey] as? String
        )
    }
    
    /// The JSON representation for the `Metadata` instance.
    public func toJson() -> [String : AnyObject] {
        var json: [String : AnyObject] = [:]
        if let lmtString = lmtString {
            json[Metadata.LmtKey] = lmtString
        }
        if let ectString = ectString {
            json[Metadata.EctKey] = ectString
        }
        if let authtoken = authtoken {
            json[Metadata.AuthTokenKey] = authtoken
        }
        return json
    }

}
