//
//  File.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public class File: NSObject {
    
    public var fileId: String?
    public var fileName: String?
    public var size: UInt64?
    public var mimeType: String?
    public var publicAccessible: Bool
    
    public var acl: Acl?
    public var metadata: Metadata?
    
    public var downloadURL: NSURL?
    public var expiresAt: NSDate?
    
    var uploadURL: NSURL?
    var uploadHeaders: [String : String]?
    
    public init(fileId: String? = nil, fileName: String? = nil, size: UInt64? = nil, mimeType: String? = nil, publicAccessible: Bool = false) {
        self.fileId = fileId
        self.fileName = fileName
        self.size = size
        self.mimeType = mimeType
        self.publicAccessible = publicAccessible
    }
    
}
