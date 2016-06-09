//
//  Acl.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

/// This class represents the ACL (Access Control List) for a record.
public class Acl: NSObject, Mappable {
    
    static let CreatorKey = "creator"
    static let GlobalReadKey = "gr"
    static let GlobalWriteKey = "gw"
    static let ReadersKey = "r"
    static let WritersKey = "w"
    
    private var _creator: String!
    
    /// The `userId` of the `User` used to create the record.
    public var creator: String {
        get { return _creator }
    }
    
    private var _globalRead: Bool?
    
    /// The `userId` of the `User` used to create the record.
    public var globalRead: Bool? {
        get { return _globalRead }
    }
    
    private var _globalWrite: Bool?
    
    /// The `userId` of the `User` used to create the record.
    public var globalWrite: Bool? {
        get { return _globalWrite }
    }
    
    private var _readers: [String]?
    
    /// Specifies the list of user _ids that are explicitly allowed to read the entity.
    public var readers: [String]? {
        get { return _readers }
    }
    
    private var _writers: [String]?
    
    /// Constructs an Acl instance with the `userId` of the `User` used to create the record.
    public init(
        creator: String,
        globalRead: Bool? = nil,
        globalWrite: Bool? = nil,
        readers: [String]? = nil,
        writers: [String]? = nil
    ) {
        _creator = creator
        _globalRead = globalRead
        _globalWrite = globalWrite
        _readers = readers
        _writers = writers
    }
    
    /// Specifies the list of user _ids that are explicitly allowed to modify the entity.
    public var writers: [String]? {
        get { return _writers }
    }
    
    public required init?(_ map: Map) {
        guard map[Acl.CreatorKey].value() != nil else {
            return nil
        }
    }
    
    public func mapping(map: Map) {
        _creator <- map[Acl.CreatorKey]
        _globalRead <- map[Acl.GlobalReadKey]
        _globalWrite <- map[Acl.GlobalWriteKey]
        _readers <- map[Acl.ReadersKey]
        _writers <- map[Acl.WritersKey]
    }

}
