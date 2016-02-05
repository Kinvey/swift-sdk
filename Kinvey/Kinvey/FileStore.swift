//
//  FileStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

public class FileStore {
    
    public typealias FileCompletionHandler = (File?, ErrorType?) -> Void
    public typealias FileDataCompletionHandler = (File?, NSData?, ErrorType?) -> Void
    public typealias UIntCompletionHandler = (UInt?, ErrorType?) -> Void
    public typealias FileArrayCompletionHandler = ([File]?, ErrorType?) -> Void
    
    private let client: Client
    
    public class func getInstance(client: Client = sharedClient) -> FileStore {
        return FileStore(client: client)
    }
    
    private init(client: Client) {
        self.client = client
    }

#if os(iOS)
    public func upload(file: File, image: UIImage, completionHandler: FileCompletionHandler? = nil) -> Request {
        let data = UIImagePNGRepresentation(image)!
        file.mimeType = "image/png"
        return upload(file, data: data, completionHandler: completionHandler)
    }
#endif
    
    public func upload(file: File, path: String, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(file, stream: NSInputStream(fileAtPath: path)!, completionHandler: completionHandler)
    }
    
    public func upload(file: File, stream: NSInputStream, completionHandler: FileCompletionHandler? = nil) -> Request {
        let data = NSMutableData()
        stream.open()
        var buffer = [UInt8](count: 4096, repeatedValue: 0)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            data.appendBytes(buffer, length: read)
        }
        stream.close()
        return upload(file, data: data, completionHandler: completionHandler)
    }
    
    private func fillFile(file: File, json: [String : AnyObject]) {
        if let fileId = json["_id"] as? String {
            file.fileId = fileId
        }
        if let filename = json["_filename"] as? String {
            file.fileName = filename
        }
        if let publicAccessible = json["_public"] as? Bool {
            file.publicAccessible = publicAccessible
        }
        if let acl = json["_acl"] as? [String : AnyObject] {
            file.acl = Acl(json: acl)
        }
        if let kmd = json["_kmd"] as? [String : AnyObject] {
            file.metadata = Metadata(json: kmd)
        }
        if let uploadURL = json["_uploadURL"] as? String {
            file.uploadURL = NSURL(string: uploadURL)
        }
        if let downloadURL = json["_downloadURL"] as? String {
            file.downloadURL = NSURL(string: downloadURL)
        }
        if let requiredHeaders = json["_requiredHeaders"] as? [String : String] {
            file.uploadHeaders = requiredHeaders
        }
        if let expiresAt = json["_expiresAt"] as? String {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            file.expiresAt = dateFormatter.dateFromString(expiresAt)
        }
    }
    
    private func getFileMetadata(file: File, ttl: TTL? = nil) -> (Request, Promise<File>) {
        let request = self.client.networkRequestFactory.buildBlobDownloadFile(file, ttl: ttl)
        return (request, Promise<File> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data, type: [String : AnyObject].self) {
                    self.fillFile(file, json: json)
                    fulfill(file)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        })
    }
    
    public func upload(file: File, data: NSData, completionHandler: FileCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobUploadFile(file)
        Promise<File> { fulfill, reject in //creating bucket
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK, let json = self.client.responseParser.parse(data, type: [String : AnyObject].self) {
                    self.fillFile(file, json: json)
                    fulfill(file)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { file in //uploading data
            return Promise<File> { fulfill, reject in
                let request = NSMutableURLRequest(URL: file.uploadURL!)
                request.HTTPMethod = "PUT"
                if let uploadHeaders = file.uploadHeaders {
                    for header in uploadHeaders {
                        request.setValue(header.1, forHTTPHeaderField: header.0)
                    }
                }
                let uploadTask = self.client.urlSession.uploadTaskWithRequest(request, fromData: data) { (data, response, error) -> Void in
                    if let response = response as? NSHTTPURLResponse where 200 <= response.statusCode && response.statusCode < 300 {
                        fulfill(file)
                    } else if let error = error {
                        reject(error)
                    } else {
                        reject(Error.InvalidResponse)
                    }
                }
                uploadTask.resume()
            }
        }.then { file in //fetching download url
            return self.getFileMetadata(file).1
        }.then { file in
            completionHandler?(file, nil)
        }.error { error in
            completionHandler?(file, error)
        }
        return request
    }
    
    public func refresh(file: File, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        let fileMetadata = getFileMetadata(file, ttl: ttl)
        let request = fileMetadata.0
        fileMetadata.1.then { file in
            completionHandler?(file, nil)
        }.error { error in
            completionHandler?(file, error)
        }
        return request
    }
    
    private func downloadFile(file: File, downloadURL: NSURL, completionHandler: FileDataCompletionHandler? = nil) -> NSURLSessionDownloadTaskRequest {
        let downloadTaskRequest = NSURLSessionDownloadTaskRequest(client: client, url: downloadURL)
        Promise<NSData> { fulfill, reject in
            downloadTaskRequest.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK, let data = data {
                    fulfill(data)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { data in
            completionHandler?(file, data, nil)
        }.error { error in
            completionHandler?(file, nil, error)
        }
        return downloadTaskRequest
    }
    
    public func download(file: File, ttl: TTL? = nil, completionHandler: FileDataCompletionHandler? = nil) -> Request {
        if let downloadURL = file.downloadURL, let expiresAt = file.expiresAt where expiresAt.timeIntervalSinceNow > 0 {
            return downloadFile(file, downloadURL: downloadURL, completionHandler: completionHandler)
        } else {
            let fileMetadata = getFileMetadata(file, ttl: ttl)
            fileMetadata.1.then { file in
                return Promise {
                    if let downloadURL = file.downloadURL, let expiresAt = file.expiresAt where expiresAt.timeIntervalSinceNow > 0 {
                        self.downloadFile(file, downloadURL: downloadURL, completionHandler: completionHandler)
                    } else {
                        completionHandler?(file, nil, Error.InvalidResponse)
                    }
                }
            }.error { error in
                completionHandler?(file, nil, error)
            }
            return fileMetadata.0
        }
    }
    
    public func remove(file: File, completionHandler: UIntCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobDeleteFile(file)
        Promise<UInt> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK,
                    let json = self.client.responseParser.parse(data, type: [String : AnyObject].self),
                    let count = json["count"] as? UInt
                {
                    fulfill(count)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { count in
            completionHandler?(count, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
    public func find(query: Query = Query(), ttl: TTL? = nil, completionHandler: FileArrayCompletionHandler? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobQueryFile(query, ttl: ttl)
        Promise<[File]> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response where response.isResponseOK,
                    let jsonArray = self.client.responseParser.parseArray(data, type: [String : AnyObject].self)
                {
                    var files: [File] = []
                    for json in jsonArray {
                        let file = File()
                        self.fillFile(file, json: json)
                        files.append(file)
                    }
                    fulfill(files)
                } else if let error = error {
                    reject(error)
                } else {
                    reject(Error.InvalidResponse)
                }
            })
        }.then { files in
            completionHandler?(files, nil)
        }.error { error in
            completionHandler?(nil, error)
        }
        return request
    }
    
}
