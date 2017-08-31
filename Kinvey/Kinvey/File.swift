//
//  File.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import ObjectMapper

/// Class that represents a file in the backend holding all metadata of the file, but don't hold the data itself.
open class File: Object, Mappable {
    
    /// `_id` property of the file.
    open dynamic var fileId: String?
    
    /// `_filename` property of the file.
    open dynamic var fileName: String?
    
    /// `size` property of the file.
    open let size = RealmOptional<Int64>()
    
    /// `mimeType` property of the file.
    open dynamic var mimeType: String?
    
    /// `_public` property of the file, which represents if the file is accessible without need of credentials.
    open dynamic var publicAccessible = false
    
    /// Temporary download URL String of the file.
    open dynamic var download: String?
    
    /// Temporary download URL of the file.
    open dynamic var downloadURL: URL? {
        get {
            if let download = download {
                return URL(string: download)
            }
            return nil
        }
        set {
            download = newValue?.absoluteString
        }
    }
    
    /// Temporary upload URL String of the file.
    open dynamic var upload: String?
    
    /// Temporary upload URL of the file.
    open dynamic var uploadURL: URL? {
        get {
            if let upload = upload {
                return URL(string: upload)
            }
            return nil
        }
        set {
            upload = newValue?.absoluteString
        }
    
    }

    
    /// Expiration data of the `downloadURL`.
    open dynamic var expiresAt: Date?
    
    /// ETag header used for validate the local cache
    open internal(set) dynamic var etag: String?
    
    /// Local path URL String for the cached file
    open internal(set) dynamic var path: String? {
        didSet {
            if let path = path,
                let documentURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
            {
                let baseURL = documentURL.deletingLastPathComponent()
                let relativePath = path.replacingOccurrences(of: baseURL.path, with: "~")
                if self.path != relativePath {
                    self.path = relativePath
                }
            }
        }
    }
    
    /// Local path URL for the cached file
    open internal(set) dynamic var pathURL: URL? {
        get {
            if let path = path {
                return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            }
            return nil
        }
        set {
            path = newValue?.path
        }
    }
    
    /// The `_kmd` property mapped in the Kinvey backend.
    public dynamic var metadata: Metadata?
    
    /// The `_acl` property mapped in the Kinvey backend.
    public dynamic var acl: Acl?
    
    /// Headers needed to submit the request to the `uploadURL`.
    var uploadHeaders: [String : String]?
    
    var resumeDownloadData: Data?
    
    public convenience required init?(map: Map) {
        self.init()
    }
    
    /// Constructor of a file instance.
    public convenience init(_ block: (File) -> Void) {
        self.init()
        block(self)
    }
    
    open func mapping(map: Map) {
        fileId <- map[Entity.Key.entityId]
        acl <- map[Entity.Key.acl]
        metadata <- map[Entity.Key.metadata]
        publicAccessible <- map["_public"]
        fileName <- map["_filename"]
        mimeType <- map["mimeType"]
        size.value <- map["size"]
        upload <- map["_uploadURL"]
        download <- map["_downloadURL"]
        expiresAt <- (map["_expiresAt"], KinveyDateTransform())
        uploadHeaders <- map["_requiredHeaders"]
    }
    
    open override class func primaryKey() -> String? {
        return "fileId"
    }
    
    open override class func ignoredProperties() -> [String] {
        var props = super.ignoredProperties()
        props += [
            "downloadURL",
            "pathURL",
            "uploadURL",
            "uploadHeaders",
            "resumeDownloadData"
        ]
        return props
    }
    
}
