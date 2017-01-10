//
//  Metadata.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

/// This class represents the metadata information for a record
public class Metadata: Object, Mappable, BuilderType {
    
    /// Last Modification Time Key.
    public static let LmtKey = "lmt"
    
    /// Entity Creation Time Key.
    public static let EctKey = "ect"
    
    /// Last Read Time Key.
    internal static let LrtKey = "lrt"
    
    /// Authentication Token Key.
    public static let AuthTokenKey = "authtoken"
    
    internal dynamic var lmt: String?
    internal dynamic var ect: String?
    internal dynamic var lrt: NSDate = NSDate()
    
    /// Last Read Time
    public var lastReadTime: NSDate {
        get {
            return self.lrt
        }
        set {
            lrt = newValue
        }
    }
    
    /// Last Modification Time.
    public var lastModifiedTime: NSDate? {
        get {
            return self.lmt?.toDate()
        }
        set {
            lmt = newValue?.toString()
        }
    }
    
    /// Entity Creation Time.
    public var entityCreationTime: NSDate? {
        get {
            return self.ect?.toDate()
        }
        set {
            ect = newValue?.toString()
        }
    }
    
    /// Authentication Token.
    public internal(set) var authtoken: String?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(_ map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        lmt <- map[Metadata.LmtKey]
        ect <- map[Metadata.EctKey]
        authtoken <- map[Metadata.AuthTokenKey]
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    public override class func ignoredProperties() -> [String] {
        return ["lastModifiedTime", "entityCreationTime", "lastReadTime"]
    }

}

public final class UserMetadata: Metadata {
    
    public internal(set) var emailVerification: EmailVerification?
    public internal(set) var passwordReset: PasswordReset?
    public internal(set) var userStatus: UserStatus?
    
    public override func mapping(map: Map) {
        super.mapping(map)
        
        emailVerification <- map["emailVerification"]
        passwordReset <- map["passwordReset"]
        userStatus <- map["status"]
    }
    
}

public final class EmailVerification: Object, Mappable {
    
    public internal(set) var status: String?
    public internal(set) var lastStateChangeAt:NSDate?
    public internal(set) var lastConfirmedAt:NSDate?
    public internal(set) var emailAddress:String?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(_ map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
        lastConfirmedAt <- (map["lastConfirmedAt"], KinveyDateTransform())
        emailAddress <- map["emailAddress"]
    }
}

public final class PasswordReset: Object, Mappable {
    
    public internal(set) var status: String?
    public internal(set) var lastStateChangeAt: NSDate?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(_ map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
    }
}

public final class UserStatus: Object, Mappable {
    
    public internal(set) var value: String?
    public internal(set) var lastChange: NSDate?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(_ map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: AnyObject, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        value <- map["val"]
        lastChange <- (map["lastChange"], KinveyDateTransform())
    }
    
}
