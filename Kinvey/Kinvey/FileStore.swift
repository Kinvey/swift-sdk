//
//  FileStore.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper


#if !os(macOS)
    import UIKit
#endif

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

public enum ImageRepresentation {
    
    case png
    case jpeg(compressionQuality: Float)

#if !os(macOS)
    func data(image: UIImage) -> Data? {
        switch self {
        case .png:
            return UIImagePNGRepresentation(image)
        case .jpeg(let compressionQuality):
            return UIImageJPEGRepresentation(image, CGFloat(compressionQuality))
        }
    }
#endif
    
    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        }
    }
    
}

/// Class to interact with the `Files` collection in the backend.
open class FileStore {
    
    public typealias FileCompletionHandler = (File?, Swift.Error?) -> Void
    public typealias FileDataCompletionHandler = (File?, Data?, Swift.Error?) -> Void
    public typealias FilePathCompletionHandler = (File?, URL?, Swift.Error?) -> Void
    public typealias UIntCompletionHandler = (UInt?, Swift.Error?) -> Void
    public typealias FileArrayCompletionHandler = ([File]?, Swift.Error?) -> Void
    
    internal let client: Client
    internal let cache: FileCache?
    
    /// Factory method that returns a `FileStore`.
    open class func getInstance(_ client: Client = sharedClient) -> FileStore {
        return FileStore(client: client)
    }
    
    fileprivate init(client: Client) {
        self.client = client
        self.cache = client.cacheManager.fileCache(fileURL: client.fileURL())
    }

#if !os(macOS)
    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(_ file: File, image: UIImage, imageRepresentation: ImageRepresentation = .png, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(
            file,
            image: image,
            imageRepresentation: imageRepresentation,
            ttl: ttl
        ) { (result: Result<File, Swift.Error>) in
            switch result {
            case .success(let file):
                completionHandler?(file, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(_ file: File, image: UIImage, imageRepresentation: ImageRepresentation = .png, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        let data = imageRepresentation.data(image: image)!
        file.mimeType = imageRepresentation.mimeType
        return upload(file, data: data, ttl: ttl, completionHandler: completionHandler)
    }
#endif
    
    /// Uploads a file using the file path.
    @discardableResult
    open func upload(_ file: File, path: String, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(
            file,
            path: path,
            ttl: ttl
        ) { (result: Result<File, Swift.Error>) in
            switch result {
            case .success(let file):
                completionHandler?(file, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Uploads a file using the file path.
    @discardableResult
    open func upload(_ file: File, path: String, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        return upload(file, fromSource: .url(URL(fileURLWithPath: path)), ttl: ttl, completionHandler: completionHandler)
    }
    
    /// Uploads a file using a input stream.
    @discardableResult
    open func upload(_ file: File, stream: InputStream, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(
            file,
            stream: stream,
            ttl: ttl
        ) { (result: Result<File, Swift.Error>) in
            switch result {
            case .success(let file):
                completionHandler?(file, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Uploads a file using a input stream.
    @discardableResult
    open func upload(_ file: File, stream: InputStream, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        return upload(file, fromSource: .stream(stream), ttl: ttl, completionHandler: completionHandler)
    }

    fileprivate func getFileMetadata(_ file: File, ttl: TTL? = nil) -> (request: Request, promise: Promise<File>) {
        let request = self.client.networkRequestFactory.buildBlobDownloadFile(file, ttl: ttl)
        let promise = Promise<File> { fulfill, reject in
            request.execute() { (data, response, error) -> Void in
                if let response = response, response.isOK,
                    let json = self.client.responseParser.parse(data),
                    let newFile = File(JSON: json) {
                    newFile.path = file.path
                    if let cache = self.cache {
                        cache.save(newFile, beforeSave: nil)
                    }
                    
                    fulfill(newFile)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }
        return (request: request, promise: promise)
    }
    
    /// Uploads a file using a `NSData`.
    @discardableResult
    open func upload(_ file: File, data: Data, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return upload(
            file,
            data: data,
            ttl: ttl
        ) { (result: Result<File, Swift.Error>) in
            switch result {
            case .success(let file):
                completionHandler?(file, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Uploads a file using a `NSData`.
    @discardableResult
    open func upload(_ file: File, data: Data, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        return upload(file, fromSource: .data(data), ttl: ttl, completionHandler: completionHandler)
    }
    
    fileprivate enum InputSource {
        
        case data(Data)
        case url(URL)
        case stream(InputStream)
        
    }
    
    /// Uploads a file using a `NSData`.
    fileprivate func upload(_ file: File, fromSource source: InputSource, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        if file.size.value == nil {
            switch source {
            case let .data(data):
                file.size.value = IntMax(data.count)
            case let .url(url):
                if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                    let fileSize = attrs[.size] as? IntMax
                {
                    file.size.value = fileSize
                }
            default:
                break
            }
        }
        let requests = MultiRequest()
        Promise<(file: File, skip: Int?)> { fulfill, reject in //creating bucket
            let createUpdateFileEntry = {
                let request = self.client.networkRequestFactory.buildBlobUploadFile(file)
                requests += request
                request.execute { (data, response, error) -> Void in
                    if let response = response , response.isOK,
                        let json = self.client.responseParser.parse(data),
                        let newFile = File(JSON: json) {
                        
                        fulfill((file: newFile, skip: nil))
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                }
            }
            
            if let _ = file.fileId,
                let uploadURL = file.uploadURL
            {
                var request = URLRequest(url: uploadURL)
                request.httpMethod = "PUT"
                if let uploadHeaders = file.uploadHeaders {
                    for (headerField, value) in uploadHeaders {
                        request.setValue(value, forHTTPHeaderField: headerField)
                    }
                }
                request.setValue("0", forHTTPHeaderField: "Content-Length")
                switch source {
                case let .data(data):
                    request.setValue("bytes */\(data.count)", forHTTPHeaderField: "Content-Range")
                case let .url(url):
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: (url.path as NSString).expandingTildeInPath),
                        let fileSize = attrs[FileAttributeKey.size] as? UIntMax
                    {
                        request.setValue("bytes */\(fileSize)", forHTTPHeaderField: "Content-Range")
                    }
                case .stream:
                    request.setValue("bytes */*", forHTTPHeaderField: "Content-Range")
                    break
                }
                
                if self.client.logNetworkEnabled {
                    do {
                        log.debug("\(request)")
                    }
                }
                
                let dataTask = self.client.urlSession.dataTask(with: request) { (data, response, error) in
                    if self.client.logNetworkEnabled, let response = response as? HTTPURLResponse {
                        do {
                            log.debug("\(response.description(data))")
                        }
                    }
                    
                    let regexRange = try! NSRegularExpression(pattern: "[bytes=]?(\\d+)-(\\d+)", options: [])
                    if let response = response as? HTTPURLResponse , 200 <= response.statusCode && response.statusCode < 300 {
                        createUpdateFileEntry()
                    } else if let response = response as? HTTPURLResponse,
                        response.statusCode == 308,
                        let rangeString = response.allHeaderFields["Range"] as? String,
                        let textCheckingResult = regexRange.matches(in: rangeString, options: [], range: NSMakeRange(0, rangeString.characters.count)).first,
                        textCheckingResult.numberOfRanges == 3
                    {
                        let rangeNSString = rangeString as NSString
                        let endRangeString = rangeNSString.substring(with: textCheckingResult.rangeAt(2))
                        if let endRange = Int(endRangeString) {
                            fulfill((file: file, skip: endRange))
                        } else {
                            reject(Error.invalidResponse(httpResponse: response, data: data))
                        }
                    } else {
                        reject(buildError(data, HttpResponse(response: response), error, self.client))
                    }
                }
                requests += URLSessionTaskRequest(client: client, task: dataTask)
                dataTask.resume()
            } else {
                createUpdateFileEntry()
            }
        }.then { file, skip in //uploading data
            return Promise<File> { fulfill, reject in
                var request = URLRequest(url: file.uploadURL!)
                request.httpMethod = "PUT"
                if let uploadHeaders = file.uploadHeaders {
                    for (headerField, value) in uploadHeaders {
                        request.setValue(value, forHTTPHeaderField: headerField)
                    }
                }
                
                let handler: (Data?, URLResponse?, Swift.Error?) -> Void = { data, response, error in
                    if self.client.logNetworkEnabled, let response = response as? HTTPURLResponse {
                        do {
                            log.debug("\(response.description(data))")
                        }
                    }
                    
                    if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode < 300 {
                        switch source {
                        case let .url(url):
                            file.path = url.path
                        default:
                            break
                        }
                        
                        fulfill(file)
                    } else {
                        reject(buildError(data, HttpResponse(response: response), error, self.client))
                    }
                }
                
                switch source {
                case let .data(data):
                    let uploadData: Data
                    if let skip = skip {
                        let startIndex = skip + 1
                        uploadData = data.subdata(in: startIndex ..< data.count - startIndex)
                        request.setValue("bytes \(startIndex)-\(data.count - 1)/\(data.count)", forHTTPHeaderField: "Content-Range")
                    } else {
                        uploadData = data
                    }
                    
                    if self.client.logNetworkEnabled {
                        do {
                            log.debug("\(request.description)")
                        }
                    }
                    
                    let uploadTask = self.client.urlSession.uploadTask(with: request, from: uploadData) { (data, response, error) -> Void in
                        handler(data, response, error)
                    }
                    requests += (URLSessionTaskRequest(client: self.client, task: uploadTask), addProgress: true)
                    uploadTask.resume()
                case let .url(url):
                    if self.client.logNetworkEnabled {
                        do {
                            log.debug("\(request.description)")
                        }
                    }
                    
                    let uploadTask = self.client.urlSession.uploadTask(with: request, fromFile: url) { (data, response, error) -> Void in
                        handler(data, response, error)
                    }
                    requests += (URLSessionTaskRequest(client: self.client, task: uploadTask), addProgress: true)
                    uploadTask.resume()
                case let .stream(stream):
                    request.httpBodyStream = stream
                    
                    if self.client.logNetworkEnabled {
                        do {
                            log.debug("\(request.description)")
                        }
                    }
                    
                    let dataTask = self.client.urlSession.dataTask(with: request) { (data, response, error) -> Void in
                        handler(data, response, error)
                    }
                    requests += (URLSessionTaskRequest(client: self.client, task: dataTask), addProgress: true)
                    dataTask.resume()
                }
            }
        }.then { file in //fetching download url
            let (request, promise) = self.getFileMetadata(file, ttl: ttl)
            requests += request
            return promise
        }.then { file in
            completionHandler?(.success(file))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return requests
    }
    
    /// Refresh a `File` instance.
    @discardableResult
    open func refresh(_ file: File, ttl: TTL? = nil, completionHandler: FileCompletionHandler? = nil) -> Request {
        return refresh(
            file,
            ttl: ttl
        ) { (result: Result<File, Swift.Error>) in
            switch result {
            case .success(let file):
                completionHandler?(file, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Refresh a `File` instance.
    @discardableResult
    open func refresh(_ file: File, ttl: TTL? = nil, completionHandler: ((Result<File, Swift.Error>) -> Void)? = nil) -> Request {
        let (request, promise) = getFileMetadata(file, ttl: ttl)
        promise.then { file in
            completionHandler?(.success(file))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    @discardableResult
    fileprivate func downloadFileURL(_ file: File, storeType: StoreType = .cache, downloadURL: URL) -> (request: URLSessionTaskRequest, promise: Promise<URL>) {
        let downloadTaskRequest = URLSessionTaskRequest(client: client, url: downloadURL)
        let promise = Promise<URL> { fulfill, reject in
            let executor = Executor()
            downloadTaskRequest.downloadTaskWithURL(file) { (url: URL?, response, error) in
                if let response = response , response.isOK || response.isNotModified, let url = url {
                    if storeType == .cache {
                        var pathURL: URL? = nil
                        var entityId: String? = nil
                        executor.executeAndWait {
                            entityId = file.fileId
                            pathURL = file.pathURL
                        }
                        if let pathURL = pathURL , response.isNotModified {
                            fulfill(pathURL)
                        } else {
                            let fileManager = FileManager()
                            if let entityId = entityId,
                                let baseFolder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
                            {
                                do {
                                    var baseFolderURL = URL(fileURLWithPath: baseFolder)
                                    baseFolderURL = baseFolderURL.appendingPathComponent(self.client.appKey!).appendingPathComponent("files")
                                    if !fileManager.fileExists(atPath: baseFolderURL.path) {
                                        try fileManager.createDirectory(at: baseFolderURL, withIntermediateDirectories: true, attributes: nil)
                                    }
                                    let toURL = baseFolderURL.appendingPathComponent(entityId)
                                    if fileManager.fileExists(atPath: toURL.path) {
                                        do {
                                            try fileManager.removeItem(atPath: toURL.path)
                                        }
                                    }
                                    try fileManager.moveItem(at: url, to: toURL)
                                    
                                    if let cache = self.cache {
                                        cache.save(file) {
                                            file.path = NSString(string: toURL.path).abbreviatingWithTildeInPath
                                            file.etag = response.etag
                                        }
                                    }
                                    
                                    fulfill(toURL)
                                } catch let error {
                                    reject(error)
                                }
                            } else {
                                reject(Error.invalidResponse(httpResponse: response.httpResponse, data: nil))
                            }
                        }
                    } else {
                        fulfill(url)
                    }
                } else {
                    reject(buildError(nil, response, error, self.client))
                }
            }
        }
        return (request: downloadTaskRequest, promise: promise)
    }
    
    @discardableResult
    fileprivate func downloadFileData(_ file: File, downloadURL: URL) -> (request: URLSessionTaskRequest, promise: Promise<Data>) {
        let downloadTaskRequest = URLSessionTaskRequest(client: client, url: downloadURL)
        let promise = downloadTaskRequest.downloadTaskWithURL(file).then { data, response -> Promise<Data> in
            return Promise<Data> { fulfill, reject in
                fulfill(data)
            }
        }
        return (request: downloadTaskRequest, promise: promise)
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ entityId: String) -> File? {
        if let cache = cache {
            return cache.get(entityId)
        }
        return nil
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ file: inout File) {
        guard let entityId = file.fileId else {
            fatalError("fileId is required")
        }
        
        if let cachedFile = cachedFile(entityId) {
            file = cachedFile
        }
    }
    
    fileprivate func crashIfInvalid(file: File) {
        guard let _ = file.fileId else {
            fatalError("fileId is required")
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, storeType: StoreType = .cache, ttl: TTL? = nil, completionHandler: FilePathCompletionHandler? = nil) -> Request {
        return download(
            file,
            storeType: storeType,
            ttl: ttl
        ) { (result: Result<(File, URL), Swift.Error>) in
            switch result {
            case .success(let file, let url):
                completionHandler?(file, url, nil)
            case .failure(let error):
                completionHandler?(nil, nil, error)
            }
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, storeType: StoreType = .cache, ttl: TTL? = nil, completionHandler: ((Result<(File, URL), Swift.Error>) -> Void)? = nil) -> Request {
        crashIfInvalid(file: file)
        
        if storeType == .sync || storeType == .cache,
            let entityId = file.fileId,
            let cachedFile = cachedFile(entityId),
            let pathURL = file.pathURL
        {
            DispatchQueue.main.async {
                completionHandler?(.success(cachedFile, pathURL))
            }
        }
        
        if storeType == .cache || storeType == .network {
            let multiRequest = MultiRequest()
            Promise<(File, URL)> { fulfill, reject in
                if let downloadURL = file.downloadURL, file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                    fulfill((file, downloadURL))
                } else {
                    let (request, promise) = getFileMetadata(file, ttl: ttl)
                    multiRequest += request
                    promise.then { (file) -> Void in
                        if let downloadURL = file.downloadURL {
                            fulfill((file, downloadURL))
                        } else {
                            throw Error.invalidResponse(httpResponse: nil, data: nil)
                        }
                    }.catch { error in
                        reject(error)
                    }
                }
            }.then { (file, downloadURL) -> Promise<(File, URL)> in
                let (request, promise) = self.downloadFileURL(file, storeType: storeType, downloadURL: downloadURL)
                multiRequest += (request, true)
                return promise.then { localUrl in
                    return Promise<(File, URL)> { fulfill, reject in
                        fulfill((file, localUrl))
                    }
                }
            }.then { file, localUrl -> Void in
                completionHandler?(.success(file, localUrl))
            }.catch { error in
                completionHandler?(.failure(error))
            }
            return multiRequest
        } else {
            return LocalRequest()
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, ttl: TTL? = nil, completionHandler: FileDataCompletionHandler? = nil) -> Request {
        return download(
            file,
            ttl: ttl
        ) { (result: Result<(File, Data), Swift.Error>) in
            switch result {
            case .success(let file, let data):
                completionHandler?(file, data, nil)
            case .failure(let error):
                completionHandler?(nil, nil, error)
            }
        }
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(_ file: File, ttl: TTL? = nil, completionHandler: ((Result<(File, Data), Swift.Error>) -> Void)? = nil) -> Request {
        crashIfInvalid(file: file)
        
        if let entityId = file.fileId, let cachedFile = cachedFile(entityId), let path = file.path, let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            DispatchQueue.main.async {
                completionHandler?(.success(cachedFile, data))
            }
        }
        
        let multiRequest = MultiRequest()
        Promise<(File, URL)> { fulfill, reject in
            if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                fulfill((file, downloadURL))
            } else {
                let (request, promise) = getFileMetadata(file, ttl: ttl)
                multiRequest += request
                promise.then { file -> Void in
                    if let downloadURL = file.downloadURL , file.publicAccessible || file.expiresAt?.timeIntervalSinceNow > 0 {
                        fulfill(file, downloadURL)
                    } else {
                        throw Error.invalidResponse(httpResponse: nil, data: nil)
                    }
                }.catch { error in
                    reject(error)
                }
            }
        }.then { (file, downloadURL) -> Promise<Data> in
            let (request, promise) = self.downloadFileData(file, downloadURL: downloadURL)
            multiRequest += (request, addProgress: true)
            return promise
        }.then { data in
            completionHandler?(.success(file, data))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return multiRequest
    }
    
    /// Deletes a file instance in the backend.
    @discardableResult
    open func remove(_ file: File, completionHandler: UIntCompletionHandler? = nil) -> Request {
        return remove(file) { (result: Result<UInt, Swift.Error>) in
            switch result {
            case .success(let count):
                completionHandler?(count, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Deletes a file instance in the backend.
    @discardableResult
    open func remove(_ file: File, completionHandler: ((Result<UInt, Swift.Error>) -> Void)? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobDeleteFile(file)
        Promise<UInt> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response , response.isOK,
                    let json = self.client.responseParser.parse(data),
                    let count = json["count"] as? UInt
                {
                    if let cache = self.cache {
                        cache.remove(file)
                    }
                    
                    fulfill(count)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            })
        }.then { count in
            completionHandler?(.success(count))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Gets a list of files that matches with the query passed by parameter.
    @discardableResult
    open func find(_ query: Query = Query(), ttl: TTL? = nil, completionHandler: FileArrayCompletionHandler? = nil) -> Request {
        return find(
            query,
            ttl: ttl
        ) { (result: Result<[File], Swift.Error>) in
            switch result {
            case .success(let files):
                completionHandler?(files, nil)
            case .failure(let error):
                completionHandler?(nil, error)
            }
        }
    }
    
    /// Gets a list of files that matches with the query passed by parameter.
    @discardableResult
    open func find(_ query: Query = Query(), ttl: TTL? = nil, completionHandler: ((Result<[File], Swift.Error>) -> Void)? = nil) -> Request {
        let request = client.networkRequestFactory.buildBlobQueryFile(query, ttl: ttl)
        Promise<[File]> { fulfill, reject in
            request.execute { (data, response, error) -> Void in
                if let response = response,
                    response.isOK,
                    let jsonArray = self.client.responseParser.parseArray(data),
                    let files = [File](JSONArray: jsonArray)
                {
                    fulfill(files)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }.then { files in
            completionHandler?(.success(files))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /**
     Clear cached files from local storage.
     */
    open func clearCache() {
        client.cacheManager.clearAll()
    }
    
}
