//
//  UserQuery.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/**
 Struct that contains all the parameters available for user lookup.
 */
public final class UserQuery: BuilderType {
    
    /// Filter by User's ID
    public var userId: String?
    
    /// Filter by User's Username
    public var username: String?
    
    /// Filter by User's First Name
    public var firstName: String?
    
    /// Filter by User's Last Name
    public var lastName: String?
    
    /// Filter by User's Email
    public var email: String?
    
    /// Filter by User's Facebook ID
    public var facebookId: String?
    
    /// Filter by User's Facebook Name
    public var facebookName: String?
    
    /// Filter by User's Twitter ID
    public var twitterId: String?
    
    /// Filter by User's Twitter Name
    public var twitterName: String?
    
    /// Filter by User's Google ID
    public var googleId: String?
    
    /// Filter by User's Google Given Name
    public var googleGivenName: String?
    
    /// Filter by User's Google Family Name
    public var googleFamilyName: String?
    
    /// Filter by User's LinkedIn ID
    public var linkedInId: String?
    
    /// Filter by User's LinkedIn First Name
    public var linkedInFirstName: String?
    
    /// Filter by User's LinkedIn Last Name
    public var linkedInLastName: String?
    
    /// Default Constructor.
    public init() {
    }
    
}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension UserQuery: Mappable {
    
    /// Constructor for object mapping.
    public convenience init?(map: Map) {
        self.init()
    }
    
    /// Performs the object mapping.
    public func mapping(map: Map) {
        userId <- ("_id", map["_id"])
        username <- ("username", map["username"])
        firstName <- ("first_name", map["first_name"])
        lastName <- ("last_name", map["last_name"])
        email <- ("email", map["email"])
        facebookId <- ("_socialIdentity.facebook.id", map["_socialIdentity.facebook.id"])
        facebookName <- ("_socialIdentity.facebook.name", map["_socialIdentity.facebook.name"])
        twitterId <- ("_socialIdentity.twitter.id", map["_socialIdentity.twitter.id"])
        twitterName <- ("_socialIdentity.twitter.name", map["_socialIdentity.twitter.name"])
        googleId <- ("_socialIdentity.google.id", map["_socialIdentity.google.id"])
        googleGivenName <- ("_socialIdentity.google.given_name", map["_socialIdentity.google.given_name"])
        googleFamilyName <- ("_socialIdentity.google.family_name", map["_socialIdentity.google.family_name"])
        linkedInId <- ("_socialIdentity.linkedIn.id", map["_socialIdentity.linkedIn.id"])
        linkedInFirstName <- ("_socialIdentity.linkedIn.firstName", map["_socialIdentity.linkedIn.firstName"])
        linkedInLastName <- ("_socialIdentity.linkedIn.lastName", map["_socialIdentity.linkedIn.lastName"])
    }
    
}
