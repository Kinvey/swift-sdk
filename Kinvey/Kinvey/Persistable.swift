//
//  Persistable.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import CoreData
import ObjectMapper

/// Protocol that turns a NSObject into a persistable class to be used in a `DataStore`.
public protocol Persistable: Mappable {
    
    /// Provides the collection name to be matched with the backend.
    static var kinveyCollectionName: String { get }
    
    /// Provides the object id property name.
    static var kinveyObjectIdPropertyName: String { get }
    
    /// Provides the metadata property name.
    static var kinveyMetadataPropertyName: String { get }
    
    /// Provides the ACL property name.
    static var kinveyAclPropertyName: String { get }
    
}
