//
//  UserQuery.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public struct UserQuery: Mappable {
    
    public var userId: String?
    public var username: String?
    public var firstName: String?
    public var lastName: String?
    public var email: String?
    public var facebookId: String?
    public var facebookName: String?
    public var twitterId: String?
    public var twitterName: String?
    public var googleId: String?
    public var googleGivenName: String?
    public var googleFamilyName: String?
    public var linkedInId: String?
    public var linkedInFirstName: String?
    public var linkedInLastName: String?
    
    public init(@noescape _ block: (inout UserQuery) -> Void) {
        block(&self)
    }
    
    public init() {
    }
    
    public init?(_ map: Map) {
    }
    
    public mutating func mapping(map: Map) {
        userId <- map["_id"]
        username <- map["username"]
        firstName <- map["first_name"]
        lastName <- map["last_name"]
        email <- map["email"]
        facebookId <- map["_socialIdentity.facebook.id"]
        facebookName <- map["_socialIdentity.facebook.name"]
        twitterId <- map["_socialIdentity.twitter.id"]
        twitterName <- map["_socialIdentity.twitter.name"]
        googleId <- map["_socialIdentity.google.id"]
        googleGivenName <- map["_socialIdentity.google.given_name"]
        googleFamilyName <- map["_socialIdentity.google.family_name"]
        linkedInId <- map["_socialIdentity.linkedIn.id"]
        linkedInFirstName <- map["_socialIdentity.linkedIn.firstName"]
        linkedInLastName <- map["_socialIdentity.linkedIn.lastName"]
    }
    
}
