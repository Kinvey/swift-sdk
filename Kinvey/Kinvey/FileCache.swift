//
//  FileCache.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-26.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

protocol FileCache {
    
    func save(file: File, beforeSave: (() -> Void)?)
    
    func remove(file: File)
    
    func get(fileId: String) -> File?
    
}
