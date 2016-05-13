//
//  File.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Class that represents a file in the backend holding all metadata of the file, but don't hold the data itself.
@objc(KNVFile)
public class File: NSObject {
    
    /// `_id` property of the file.
    public var fileId: String?
    
    /// `_filename` property of the file.
    public var fileName: String?
    
    /// `size` property of the file.
    public var size: UInt64?
    
    /// `mimeType` property of the file.
    public var mimeType: String?
    
    /// `_public` property of the file, which represents if the file is accessible without need of credentials.
    public var publicAccessible: Bool
    
    /// `_acl` property of the file.
    public var acl: Acl?
    
    /// `_kmd` property of the file.
    public var metadata: Metadata?
    
    /// Temporary download URL of the file.
    public var downloadURL: NSURL?
    
    /// Expiration data of the `downloadURL`.
    public var expiresAt: NSDate?
    
    /// Temporary upload URL of the file.
    var uploadURL: NSURL?
    
    /// Headers needed to submit the request to the `uploadURL`.
    var uploadHeaders: [String : String]?
    
    var resumeDownloadData: NSData?
    
    /// Constructor of a file instance.
    public init(fileId: String? = nil, fileName: String? = nil, size: UInt64? = nil, mimeType: String? = nil, publicAccessible: Bool = false) {
        self.fileId = fileId
        self.fileName = fileName
        self.size = size
        self.mimeType = mimeType
        self.publicAccessible = publicAccessible
    }
    
}
