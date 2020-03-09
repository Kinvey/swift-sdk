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

/// Class that represents a file in the backend holding all metadata of the file, but don't hold the data itself.
open class File: Object, JSONCodable {

    /// `_id` property of the file.
    @objc
    open dynamic var fileId: String?
    
    /// `_filename` property of the file.
    @objc
    open dynamic var fileName: String?
    
    /// `size` property of the file.
    public let size = RealmOptional<Int64>()
    
    /// `mimeType` property of the file.
    @objc
    open dynamic var mimeType: String?
    
    /// `_public` property of the file, which represents if the file is accessible without need of credentials.
    @objc
    open dynamic var publicAccessible = false
    
    /// Temporary download URL String of the file.
    @objc
    open dynamic var download: String?
    
    /// Temporary download URL of the file.
    @objc
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
    @objc
    open dynamic var upload: String?
    
    /// Temporary upload URL of the file.
    @objc
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
    @objc
    open dynamic var expiresAt: Date?
    
    /// ETag header used for validate the local cache
    @objc
    open internal(set) dynamic var etag: String?
    
    /// Local path URL String for the cached file
    @objc
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
    @objc
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
    @objc
    public dynamic var metadata: Metadata?
    
    /// The `_acl` property mapped in the Kinvey backend.
    @objc
    public dynamic var acl: Acl?
    
    /// Headers needed to submit the request to the `uploadURL`.
    var uploadHeaders: [String : String]?
    
    var resumeDownloadData: Data?
    
    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
    public convenience required init?(map: Map) {
        self.init()
    }
    
    /// Constructor of a file instance.
    public convenience init(_ block: (File) -> Void) {
        self.init()
        block(self)
    }
    
    public enum FileCodingKeys: String, CodingKey {
        case entityId = "_id"
        case acl = "_acl"
        case metadata = "_kmd"
        case publicAccessible = "_public"
        case fileName = "_filename"
        case mimeType
        case size
        case upload = "_uploadURL"
        case download = "_downloadURL"
        case expiresAt = "_expiresAt"
        case uploadHeaders = "_requiredHeaders"
        
    }

    public required init() {
        super.init()
    }
    
    public required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    public required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
    public init(from decoder: Decoder) throws {
        super.init()
        
        let container = try decoder.container(keyedBy: FileCodingKeys.self)
        fileId = try container.decodeIfPresent(String.self, forKey: .entityId)
        acl = try container.decodeIfPresent(Acl.self, forKey: .acl)
        metadata = try container.decodeIfPresent(Metadata.self, forKey: .metadata)
        publicAccessible = try container.decodeIfPresent(Bool.self, forKey: .publicAccessible) ?? false
        fileName = try container.decodeIfPresent(String.self, forKey: .fileName)
        mimeType  = try container.decodeIfPresent(String.self, forKey: .mimeType)
        size.value = try container.decodeIfPresent(Int64.self, forKey: .size)
        upload = try container.decodeIfPresent(String.self, forKey: .upload)
        download = try container.decodeIfPresent(String.self, forKey: .download)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        uploadHeaders = try container.decodeIfPresent([String : String].self, forKey: .uploadHeaders)
    }
    
    open func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FileCodingKeys.self)

        try container.encodeIfPresent(fileId, forKey: .entityId)
        try container.encodeIfPresent(acl, forKey: .acl)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(publicAccessible, forKey: .publicAccessible)
        try container.encodeIfPresent(fileName, forKey: .fileName)
        try container.encodeIfPresent(mimeType, forKey: .mimeType)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(upload, forKey: .upload)
        try container.encodeIfPresent(download, forKey: .download)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encodeIfPresent(uploadHeaders, forKey: .uploadHeaders)

    }
    
    open class func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return try decodeArrayJSONDecodable(from: data)
    }
    
    open class func decode<T>(from data: Data) throws -> T where T: JSONDecodable {
        return try decodeJSONDecodable(from: data)
    }
    
    open class func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: dictionary)
    }
    
    open func refresh(from dictionary: [String : Any]) throws {
        var _self = self
        try _self.refreshJSONDecodable(from: dictionary)
    }
    
    open func encode() throws -> [String : Any] {
        return try encodeJSONEncodable()
    }

    @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
    open func mapping(map: Map) {
        fileId <- ("fileId", map[FileCodingKeys.entityId])
        acl <- ("acl", map[FileCodingKeys.acl])
        metadata <- ("metadata", map[FileCodingKeys.metadata])
        publicAccessible <- ("publicAccessible", map[FileCodingKeys.publicAccessible])
        fileName <- ("fileName", map[FileCodingKeys.fileName])
        mimeType <- ("mimeType", map[FileCodingKeys.mimeType])
        size.value <- ("size", map[FileCodingKeys.size])
        upload <- ("upload", map[FileCodingKeys.upload])
        download <- ("download", map[FileCodingKeys.download])
        expiresAt <- ("expiresAt", map[FileCodingKeys.expiresAt], KinveyDateTransform())
        uploadHeaders <- ("uploadHeaders", map[FileCodingKeys.uploadHeaders])
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

@available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
extension File : Mappable {
}
