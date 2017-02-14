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
import ObjectMapper

/// This class represents the metadata information for a record
public class Metadata: Object, Mappable {
    
    /// Last Modification Time Key.
    open static let LmtKey = "lmt"
    
    /// Entity Creation Time Key.
    open static let EctKey = "ect"
    
    /// Last Read Time Key.
    internal static let LrtKey = "lrt"
    
    /// Authentication Token Key.
    open static let AuthTokenKey = "authtoken"
    
    internal dynamic var lmt: String?
    internal dynamic var ect: String?
    internal dynamic var lrt: Date = Date()
    
    /// Last Read Time
    open var lastReadTime: Date {
        get {
            return self.lrt
        }
        set {
            lrt = newValue
        }
    }
    
    /// Last Modification Time.
    open var lastModifiedTime: Date? {
        get {
            return self.lmt?.toDate()
        }
        set {
            lmt = newValue?.toString()
        }
    }
    
    /// Entity Creation Time.
    open var entityCreationTime: Date? {
        get {
            return self.ect?.toDate()
        }
        set {
            ect = newValue?.toString()
        }
    }
    
    /// Authentication Token.
    open internal(set) dynamic var authtoken: String?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(map: Map) {
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
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        lmt <- map[Metadata.LmtKey]
        ect <- map[Metadata.EctKey]
        authtoken <- map[Metadata.AuthTokenKey]
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        return ["lastModifiedTime", "entityCreationTime", "lastReadTime"]
    }

}

public final class UserMetadata: Metadata {
    
    open internal(set) var emailVerification: EmailVerification?
    open internal(set) var passwordReset: PasswordReset?
    open internal(set) var userStatus: UserStatus?
    
    open override func mapping(map: Map) {
        super.mapping(map: map)
        
        emailVerification <- map["emailVerification"]
        passwordReset <- map["passwordReset"]
        userStatus <- map["status"]
    }

}

public final class EmailVerification: Object, Mappable {
    
    open internal(set) var status: String?
    open internal(set) var lastStateChangeAt:Date?
    open internal(set) var lastConfirmedAt:Date?
    open internal(set) var emailAddress:String?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
        lastConfirmedAt <- (map["lastConfirmedAt"], KinveyDateTransform())
        emailAddress <- map["emailAddress"]
    }
}

public final class PasswordReset: Object, Mappable {
    
    open internal(set) var status: String?
    open internal(set) var lastStateChangeAt: Date?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
    }
}

public final class UserStatus: Object, Mappable {
    
    open internal(set) var value: String?
    open internal(set) var lastChange: Date?
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(map: Map) {
        super.init()
    }
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        value <- map["val"]
        lastChange <- (map["lastChange"], KinveyDateTransform())
    }

}
