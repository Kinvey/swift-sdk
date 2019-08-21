//
//  CollectionChange.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-08-21.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

public enum CollectionChange<CollectionType> {
    
    case initial(CollectionType)
    
    case update(CollectionType, deletions: [Int], insertions: [Int], modifications: [Int])
    
    case error(Swift.Error)
    
}
