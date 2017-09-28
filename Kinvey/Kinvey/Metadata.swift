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
    @available(*, deprecated: 3.5.2, message: "Please use Metadata.Key.lastModifiedTime instead")
    open static let LmtKey = "lmt"
    
    /// Entity Creation Time Key.
    @available(*, deprecated: 3.5.2, message: "Please use Metadata.Key.entityCreationTime instead")
    open static let EctKey = "ect"
    
    /// Authentication Token Key.
    @available(*, deprecated: 3.5.2, message: "Please use Metadata.Key.authToken instead")
    open static let AuthTokenKey = "authtoken"
    
    /// Property names for `Metadata`
    public struct Key {
        
        /// Last Modification Time Key.
        public static let lastModifiedTime = "lmt"
        
        /// Entity Creation Time Key.
        public static let entityCreationTime = "ect"
        
        /// Authentication Token Key.
        public static let authtoken = "authtoken"
        
        /// Last Read Time Key.
        internal static let lastReadTime = "lrt"
    
    }
    
    @objc
    internal dynamic var lmt: String?
    
    @objc
    internal dynamic var ect: String?
    
    @objc
    internal dynamic var lrt: Date = Date()
    
    /// Last Read Time
    open var lastReadTime: Date {
        get {
            return self.lrt
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
    @objc
    open internal(set) dynamic var authtoken: String?
    
    /// Default Constructor.
    public required init() {
        super.init()
    }
    
    /**
     WARNING: This is an internal initializer not intended for public use.
     :nodoc:
     */
    open override class func ignoredProperties() -> [String] {
        return ["lastModifiedTime", "entityCreationTime", "lastReadTime"]
    }
    
    // MARK: Mappable
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public required init?(map: Map) {
        super.init()
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    public func mapping(map: Map) {
        lmt <- map[Key.lastModifiedTime]
        ect <- map[Key.entityCreationTime]
        authtoken <- map[Key.authtoken]
    }
    
    // MARK: Realm
    
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

}

/// Metadata information for each `User`
public final class UserMetadata: Metadata {
    
    /// Status of the email verification process
    open internal(set) var emailVerification: EmailVerification?
    
    /// Status of the password reset process
    open internal(set) var passwordReset: PasswordReset?
    
    /// Status of the activation process
    open internal(set) var userStatus: UserStatus?
    
    public override func mapping(map: Map) {
        super.mapping(map: map)
        
        emailVerification <- map["emailVerification"]
        passwordReset <- map["passwordReset"]
        userStatus <- map["status"]
    }

}

/// Status of the email verification process for each `User`
public final class EmailVerification: Object {
    
    /// Current Status
    open internal(set) var status: String?
    
    /// Date of the last Status change
    open internal(set) var lastStateChangeAt: Date?
    
    /// Date of the last email confirmation
    open internal(set) var lastConfirmedAt: Date?
    
    /// Email Address
    open internal(set) var emailAddress: String?
    
}

/// Allows serialization and deserialization of EmailVerification
extension EmailVerification: Mappable {
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public convenience init?(map: Map) {
        self.init()
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
        lastConfirmedAt <- (map["lastConfirmedAt"], KinveyDateTransform())
        emailAddress <- map["emailAddress"]
    }
    
}

/// Status of the password reset process for each `User`
public final class PasswordReset: Object {
    
    /// Current Status
    open internal(set) var status: String?
    
    /// Date of the last Status change
    open internal(set) var lastStateChangeAt: Date?
    
}

/// Allows serialization and deserialization of PasswordReset
extension PasswordReset: Mappable {
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public convenience init?(map: Map) {
        self.init()
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        status <- map["status"]
        lastStateChangeAt <- (map["lastStateChangeAt"], KinveyDateTransform())
    }
    
}

/// Status of activation process for each `User`
public final class UserStatus: Object {
    
    /// Current Status
    open internal(set) var value: String?
    
    /// Date of the last Status change
    open internal(set) var lastChange: Date?
    
}

/// Allows serialization and deserialization of UserStatus
extension UserStatus: Mappable {
    
    /// Constructor that validates if the map can be build a new instance of Metadata.
    public convenience init?(map: Map) {
        self.init()
    }
    
    /// This function is where all variable mappings should occur. It is executed by Mapper during the mapping (serialization and deserialization) process.
    open func mapping(map: Map) {
        value <- map["val"]
        lastChange <- (map["lastChange"], KinveyDateTransform())
    }
    
}
