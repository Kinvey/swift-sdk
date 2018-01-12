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


#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// Enumeration to describe which format an image should be represented
public enum ImageRepresentation {
    
    /// PNG Format
    case png
    
    /// JPEG Format with a compression quality value
    case jpeg(compressionQuality: Float)

#if os(macOS)
    
    func data(image: NSImage) -> Data? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        let newRep = NSBitmapImageRep(cgImage: cgImage)
        newRep.size = image.size
        var fileType: NSBitmapImageRep.FileType!
        var properties: [NSBitmapImageRep.PropertyKey : Any]!
        switch self {
        case .png:
            fileType = .png
            properties = [:]
        case .jpeg(let compressionQuality):
            fileType = .jpeg
            properties = [.compressionFactor : compressionQuality]
        }
        return newRep.representation(using: fileType, properties: properties)
    }
    
#else

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
open class FileStore<FileType: File> {
    
    public typealias FileCompletionHandler = (FileType?, Swift.Error?) -> Void
    public typealias FileDataCompletionHandler = (FileType?, Data?, Swift.Error?) -> Void
    public typealias FilePathCompletionHandler = (FileType?, URL?, Swift.Error?) -> Void
    public typealias UIntCompletionHandler = (UInt?, Swift.Error?) -> Void
    public typealias FileArrayCompletionHandler = ([FileType]?, Swift.Error?) -> Void
    
    internal let client: Client
    internal let cache: AnyFileCache<FileType>?
    
    /// Factory method that returns a `FileStore`.
    @available(*, deprecated: 3.5.2, message: "Please use the constructor instead")
    open class func getInstance<FileType: File>(client: Client = sharedClient) -> FileStore<FileType> {
        return FileStore<FileType>(client: client)
    }
    
    /// Factory method that returns a `FileStore`.
    @available(*, deprecated: 3.5.2, message: "Please use the constructor instead")
    open class func getInstance<FileType: File>(fileType: FileType.Type, client: Client = sharedClient) -> FileStore<FileType> {
        return FileStore<FileType>(client: client)
    }
    
    /**
     Constructor that takes a specific `Client` instance or use the
     `sharedClient` instance
     */
    public init(client: Client = sharedClient) {
        self.client = client
        self.cache = client.cacheManager.fileCache(fileURL: client.fileURL())
    }

#if os(macOS)
    
    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(
        _ file: FileType,
        image: NSImage,
        imageRepresentation: ImageRepresentation = .png,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return upload(
            file,
            image: image,
            imageRepresentation: imageRepresentation,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func upload(
        _ file: FileType,
        image: NSImage,
        imageRepresentation: ImageRepresentation = .png,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            image: image,
            imageRepresentation: imageRepresentation,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(
        _ file: FileType,
        image: NSImage,
        imageRepresentation: ImageRepresentation = .png,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let data = imageRepresentation.data(image: image)!
        file.mimeType = imageRepresentation.mimeType
        return upload(
            file,
            data: data,
            options: options,
            completionHandler: completionHandler
        )
    }
    
#else

    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(
        _ file: FileType,
        image: UIImage,
        imageRepresentation: ImageRepresentation = .png,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return upload(
            file,
            image: image,
            imageRepresentation: imageRepresentation,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func upload(
        _ file: FileType,
        image: UIImage,
        imageRepresentation: ImageRepresentation = .png,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            image: image,
            imageRepresentation: imageRepresentation,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a `UIImage` in a PNG or JPEG format.
    @discardableResult
    open func upload(
        _ file: FileType,
        image: UIImage,
        imageRepresentation: ImageRepresentation = .png,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let data = imageRepresentation.data(image: image)!
        file.mimeType = imageRepresentation.mimeType
        return upload(
            file,
            data: data,
            options: options,
            completionHandler: completionHandler
        )
    }

#endif
    
    /// Uploads a file using the file path.
    @discardableResult
    open func upload(
        _ file: FileType,
        path: String,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return upload(
            file,
            path: path,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func upload(
        _ file: FileType,
        path: String,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            path: path,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a file using the file path.
    @discardableResult
    open func upload(
        _ file: FileType,
        path: String,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            fromSource: .url(URL(fileURLWithPath: (path as NSString).expandingTildeInPath)),
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a file using a input stream.
    @discardableResult
    open func upload(
        _ file: FileType,
        stream: InputStream,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return upload(
            file,
            stream: stream,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func upload(
        _ file: FileType,
        stream: InputStream,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            stream: stream,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a file using a input stream.
    @discardableResult
    open func upload(
        _ file: FileType,
        stream: InputStream,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            fromSource: .stream(stream),
            options: options,
            completionHandler: completionHandler
        )
    }

    fileprivate func getFileMetadata(
        _ file: FileType,
        options: Options?,
        requests: MultiRequest? = nil
    ) -> (request: Request, promise: Promise<FileType>) {
        let request = self.client.networkRequestFactory.buildBlobDownloadFile(
            file,
            options: options
        )
        let promise = Promise<FileType> { fulfill, reject in
            request.execute() { (data, response, error) -> Void in
                if let response = response, response.isOK,
                    let json = self.client.responseParser.parse(data),
                    let newFile = FileType(JSON: json) {
                    newFile.path = file.path
                    if let cache = self.cache {
                        cache.save(newFile, beforeSave: nil)
                    }
                    
                    fulfill(newFile)
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
            if let requests = requests {
                requests.progress.addChild(request.progress, withPendingUnitCount: 1)
                requests += request
            }
        }
        return (request: request, promise: promise)
    }
    
    /// Uploads a file using a `NSData`.
    @discardableResult
    open func upload(
        _ file: FileType,
        data: Data,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return upload(
            file,
            data: data,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func upload(
        _ file: FileType,
        data: Data,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            data: data,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Uploads a file using a `NSData`.
    @discardableResult
    open func upload(
        _ file: FileType,
        data: Data,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            fromSource: .data(data),
            options: options,
            completionHandler: completionHandler
        )
    }
    
    fileprivate enum InputSource {
        
        case data(Data)
        case url(URL)
        case stream(InputStream)
        
    }
    
    /// Uploads a file using a `NSData`.
    fileprivate func upload(
        _ file: FileType,
        fromSource source: InputSource,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return upload(
            file,
            fromSource: source,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    @discardableResult
    open func create(
        _ file: FileType,
        data: Data,
        options: Options? = nil,
        completionHandler: @escaping (Result<FileType, Swift.Error>) -> Void
    ) -> Request {
        let requests = MultiRequest()
        createBucket(
            file,
            fromSource: .data(data),
            options: options,
            requests: requests
        ).then { file, skip in
            completionHandler(.success(file))
        }.catch {
            completionHandler(.failure($0))
        }
        return requests
    }
    
    @discardableResult
    open func create(
        _ file: FileType,
        path: String,
        options: Options? = nil,
        completionHandler: @escaping (Result<FileType, Swift.Error>) -> Void
    ) -> Request {
        let requests = MultiRequest()
        createBucket(
            file,
            fromSource: .url(URL(fileURLWithPath: (path as NSString).expandingTildeInPath)),
            options: options,
            requests: requests
        ).then { file, skip in
            completionHandler(.success(file))
        }.catch {
            completionHandler(.failure($0))
        }
        return requests
    }
    
    @discardableResult
    open func create(
        _ file: FileType,
        stream: InputStream,
        options: Options? = nil,
        completionHandler: @escaping (Result<FileType, Swift.Error>) -> Void
    ) -> Request {
        let requests = MultiRequest()
        createBucket(
            file,
            fromSource: .stream(stream),
            options: options,
            requests: requests
        ).then { file, skip in
            completionHandler(.success(file))
        }.catch {
            completionHandler(.failure($0))
        }
        return requests
    }
    
    fileprivate func createBucket(
        _ file: FileType,
        fromSource source: InputSource,
        options: Options?,
        requests: MultiRequest
    ) -> Promise<(file: FileType, skip: Int?)> {
        return Promise<(file: FileType, skip: Int?)> { fulfill, reject in //creating bucket
            if file.size.value == nil {
                switch source {
                case let .data(data):
                    file.size.value = Int64(data.count)
                case let .url(url):
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let fileSize = attrs[.size] as? Int64
                    {
                        file.size.value = fileSize
                    }
                default:
                    break
                }
            }
            
            let createUpdateFileEntry = {
                let request = self.client.networkRequestFactory.buildBlobUploadFile(file, options: options)
                requests += request
                request.execute { (data, response, error) -> Void in
                    if let response = response, response.isOK,
                        let json = self.client.responseParser.parse(data),
                        let newFile = FileType(JSON: json)
                    {
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
                        let fileSize = attrs[FileAttributeKey.size] as? UInt64
                    {
                        request.setValue("bytes */\(fileSize)", forHTTPHeaderField: "Content-Range")
                    }
                case .stream:
                    request.setValue("bytes */*", forHTTPHeaderField: "Content-Range")
                    break
                }
                
                if self.client.logNetworkEnabled {
                    do {
                        log.debug("\(request.description)")
                    }
                }
                
                let urlSession = options?.urlSession ?? client.urlSession
                let dataTask = urlSession.dataTask(with: request) { (data, response, error) in
                    if self.client.logNetworkEnabled, let response = response as? HTTPURLResponse {
                        do {
                            log.debug("\(response.description(data))")
                        }
                    }
                    
                    let regexRange = try! NSRegularExpression(pattern: "[bytes=]?(\\d+)-(\\d+)")
                    if let response = response as? HTTPURLResponse, 200 <= response.statusCode && response.statusCode < 300 {
                        createUpdateFileEntry()
                    } else if let response = response as? HTTPURLResponse,
                        response.statusCode == 308
                    {
                        if let rangeString = response.allHeaderFields["Range"] as? String,
                            let textCheckingResult = regexRange.matches(in: rangeString, range: NSMakeRange(0, rangeString.count)).first,
                            textCheckingResult.numberOfRanges == 3
                        {
                            let endRangeString = rangeString.substring(with: textCheckingResult.range(at: 2))
                            if let endRange = Int(endRangeString) {
                                fulfill((file: file, skip: endRange))
                            } else {
                                reject(Error.invalidResponse(httpResponse: response, data: data))
                            }
                        } else {
                            fulfill((file: file, skip: nil))
                        }
                    } else {
                        reject(buildError(data, HttpResponse(response: response), error, self.client))
                    }
                }
                let urlSessionTaskRequest = URLSessionTaskRequest(client: client, options: options, task: dataTask)
                requests.progress.addChild(urlSessionTaskRequest.progress, withPendingUnitCount: 1)
                requests += urlSessionTaskRequest
                dataTask.resume()
            } else {
                createUpdateFileEntry()
            }
        }
    }
    
    fileprivate func upload(
        _ file: FileType,
        fromSource source: InputSource,
        skip: Int?,
        options: Options?,
        requests: MultiRequest
    ) -> Promise<FileType> {
        return Promise<FileType> { fulfill, reject in
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
            
            let urlSession = options?.urlSession ?? client.urlSession
            
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
                
                let uploadTask = urlSession.uploadTask(with: request, from: uploadData) { (data, response, error) -> Void in
                    handler(data, response, error)
                }
                let urlSessionTaskRequest = URLSessionTaskRequest(client: self.client, options: options, task: uploadTask)
                requests.progress.addChild(urlSessionTaskRequest.progress, withPendingUnitCount: 98)
                requests += urlSessionTaskRequest
                uploadTask.resume()
            case let .url(url):
                if self.client.logNetworkEnabled {
                    do {
                        log.debug("\(request.description)")
                    }
                }
                
                let uploadTask = urlSession.uploadTask(with: request, fromFile: url) { (data, response, error) -> Void in
                    handler(data, response, error)
                }
                let urlSessionTaskRequest = URLSessionTaskRequest(client: self.client, options: options, task: uploadTask)
                requests.progress.addChild(urlSessionTaskRequest.progress, withPendingUnitCount: 98)
                requests += urlSessionTaskRequest
                uploadTask.resume()
            case let .stream(stream):
                request.httpBodyStream = stream
                
                if self.client.logNetworkEnabled {
                    do {
                        log.debug("\(request.description)")
                    }
                }
                
                let dataTask = urlSession.dataTask(with: request) { (data, response, error) -> Void in
                    handler(data, response, error)
                }
                let urlSessionTaskRequest = URLSessionTaskRequest(client: self.client, options: options, task: dataTask)
                requests.progress.addChild(urlSessionTaskRequest.progress, withPendingUnitCount: 98)
                requests += urlSessionTaskRequest
                dataTask.resume()
            }
        }
    }
    
    /// Uploads a file using a `NSData`.
    fileprivate func upload(
        _ file: FileType,
        fromSource source: InputSource,
        options: Options?,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let requests = MultiRequest()
        requests.progress = Progress(totalUnitCount: 100)
        createBucket(
            file,
            fromSource: source,
            options: options,
            requests: requests
        ).then { file, skip in //uploading data
            return self.upload(
                file,
                fromSource: source,
                skip: skip,
                options: options,
                requests: requests
            )
        }.then { file -> Promise<FileType> in //fetching download url
            let (_, promise) = self.getFileMetadata(
                file,
                options: options,
                requests: requests
            )
            return promise
        }.then { file -> Void in
            requests.progress.completedUnitCount = requests.progress.totalUnitCount
            completionHandler?(.success(file))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return requests
    }
    
    /// Refresh a `File` instance.
    @discardableResult
    open func refresh(
        _ file: FileType,
        ttl: TTL? = nil,
        completionHandler: FileCompletionHandler? = nil
    ) -> Request {
        return refresh(
            file,
            ttl: ttl
        ) { (result: Result<FileType, Swift.Error>) in
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
    open func refresh(
        _ file: FileType,
        ttl: TTL? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return refresh(
            file,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Refresh a `File` instance.
    @discardableResult
    open func refresh(
        _ file: FileType,
        options: Options? = nil,
        completionHandler: ((Result<FileType, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let (request, promise) = getFileMetadata(
            file,
            options: options
        )
        promise.then { file in
            completionHandler?(.success(file))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    @discardableResult
    fileprivate func downloadFileURL(
        _ file: FileType,
        storeType: StoreType = .cache,
        downloadURL: URL,
        options: Options?
    ) -> (
        request: URLSessionTaskRequest,
        promise: Promise<URL>
    ) {
        let downloadTaskRequest = URLSessionTaskRequest(client: client, options: options, url: downloadURL)
        let promise = Promise<URL> { fulfill, reject in
            let executor = Executor()
            downloadTaskRequest.downloadTaskWithURL(file) { (url: URL?, response, error) in
                if let response = response, response.isOK || response.isNotModified, let url = url {
                    if storeType == .cache {
                        var pathURL: URL? = nil
                        var entityId: String? = nil
                        executor.executeAndWait {
                            entityId = file.fileId
                            pathURL = file.pathURL
                        }
                        if let pathURL = pathURL, response.isNotModified {
                            fulfill(pathURL)
                        } else {
                            let fileManager = FileManager()
                            if let entityId = entityId
                            {
                                let baseFolder = cacheBasePath
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
    fileprivate func downloadFileData(_ file: FileType, downloadURL: URL, options: Options?) -> (request: URLSessionTaskRequest, promise: Promise<Data>) {
        let downloadTaskRequest = URLSessionTaskRequest(client: client, options: options, url: downloadURL)
        let promise = downloadTaskRequest.downloadTaskWithURL(file).then { data, response -> Promise<Data> in
            return Promise<Data> { fulfill, reject in
                fulfill(data)
            }
        }
        return (request: downloadTaskRequest, promise: promise)
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ entityId: String) -> FileType? {
        return cache?.get(entityId)
    }
    
    /// Returns the cached file, if exists.
    open func cachedFile(_ file: FileType) -> FileType? {
        let entityId = crashIfInvalid(file: file)
        return cachedFile(entityId)
    }
    
    @discardableResult
    fileprivate func crashIfInvalid(file: FileType) -> String {
        guard let fileId = file.fileId else {
            fatalError("fileId is required")
        }
        return fileId
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(
        _ file: FileType,
        storeType: StoreType = .cache,
        ttl: TTL? = nil,
        completionHandler: FilePathCompletionHandler? = nil
    ) -> Request {
        return download(
            file,
            storeType: storeType,
            ttl: ttl
        ) { (result: Result<(FileType, URL), Swift.Error>) in
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
    open func download(
        _ file: FileType,
        storeType: StoreType = .cache,
        ttl: TTL? = nil,
        completionHandler: ((Result<(FileType, URL), Swift.Error>) -> Void)? = nil
    ) -> Request {
        return download(
            file,
            storeType: storeType,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(
        _ file: FileType,
        storeType: StoreType = .cache,
        options: Options? = nil,
        completionHandler: ((Result<(FileType, URL), Swift.Error>) -> Void)? = nil
    ) -> Request {
        crashIfInvalid(file: file)
        
        if storeType == .sync || storeType == .cache,
            let entityId = file.fileId,
            let cachedFile = cachedFile(entityId),
            let pathURL = file.pathURL
        {
            DispatchQueue.main.async {
                completionHandler?(.success((cachedFile, pathURL)))
            }
        }
        
        if storeType == .cache || storeType == .network {
            let multiRequest = MultiRequest()
            Promise<(FileType, URL)> { fulfill, reject in
                if let downloadURL = file.downloadURL,
                    file.publicAccessible ||
                    (
                        file.expiresAt != nil &&
                        file.expiresAt!.timeIntervalSinceNow > 0
                    )
                {
                    fulfill((file, downloadURL))
                } else {
                    let (request, promise) = getFileMetadata(
                        file,
                        options: options
                    )
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
            }.then { (file, downloadURL) -> Promise<(FileType, URL)> in
                let (request, promise) = self.downloadFileURL(
                    file,
                    storeType: storeType,
                    downloadURL: downloadURL,
                    options: options
                )
                multiRequest += request
                return promise.then { localUrl in
                    return Promise<(FileType, URL)> { fulfill, reject in
                        fulfill((file, localUrl))
                    }
                }
            }.then {
                completionHandler?(.success($0))
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
    open func download(
        _ file: FileType,
        ttl: TTL? = nil,
        completionHandler: FileDataCompletionHandler? = nil
    ) -> Request {
        return download(
            file,
            ttl: ttl
        ) { (result: Result<(FileType, Data), Swift.Error>) in
            switch result {
            case .success(let file, let data):
                completionHandler?(file, data, nil)
            case .failure(let error):
                completionHandler?(nil, nil, error)
            }
        }
    }
    
    private enum DownloadStage {
        
        case downloadURL(URL)
        case data(Data)
        
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(
        _ file: FileType,
        ttl: TTL? = nil,
        completionHandler: ((Result<(FileType, Data), Swift.Error>) -> Void)? = nil
    ) -> Request {
        return download(
            file,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Downloads a file using the `downloadURL` of the `File` instance.
    @discardableResult
    open func download(
        _ file: FileType,
        options: Options? = nil,
        completionHandler: ((Result<(FileType, Data), Swift.Error>) -> Void)? = nil
    ) -> Request {
        crashIfInvalid(file: file)
        
        let multiRequest = MultiRequest()
        multiRequest.progress = Progress(totalUnitCount: 100)
        Promise<(FileType, DownloadStage)> { fulfill, reject in
            if let entityId = file.fileId,
                let cachedFile = cachedFile(entityId),
                let path = file.path,
                let data = try? Data(contentsOf: URL(fileURLWithPath: path))
            {
                fulfill((cachedFile, .data(data)))
                return
            }
            
            if let downloadURL = file.downloadURL,
                file.publicAccessible ||
                (
                    file.expiresAt != nil &&
                    file.expiresAt!.timeIntervalSinceNow > 0
                )
            {
                fulfill((file, .downloadURL(downloadURL)))
            } else {
                let (request, promise) = getFileMetadata(
                    file,
                    options: options
                )
                multiRequest += request
                promise.then { file -> Void in
                    if let downloadURL = file.downloadURL,
                        file.publicAccessible ||
                        (
                            file.expiresAt != nil &&
                            file.expiresAt!.timeIntervalSinceNow > 0
                        )
                    {
                        fulfill((file, .downloadURL(downloadURL)))
                    } else {
                        throw Error.invalidResponse(httpResponse: nil, data: nil)
                    }
                }.catch { error in
                    reject(error)
                }
            }
        }.then { (file, downloadStage) in
            return Promise<(FileType, DownloadStage)> { fulfill, reject in
                multiRequest.progress.completedUnitCount = 1
                fulfill((file, downloadStage))
            }
        }.then { (file, downloadStage) -> Promise<Data> in
            switch downloadStage {
            case .downloadURL(let downloadURL):
                let (request, promise) = self.downloadFileData(
                    file,
                    downloadURL: downloadURL,
                    options: options
                )
                multiRequest.progress.addChild(request.progress, withPendingUnitCount: 99)
                multiRequest += request
                return promise
            case .data(let data):
                return Promise<Data> { fulfill, reject in
                    fulfill(data)
                }
            }
        }.then { data -> Void in
            multiRequest.progress.completedUnitCount = multiRequest.progress.totalUnitCount
            completionHandler?(.success((file, data)))
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return multiRequest
    }
    
    /// Deletes a file instance in the backend.
    @discardableResult
    open func remove(
        _ file: FileType,
        completionHandler: UIntCompletionHandler? = nil
    ) -> Request {
        return remove(
            file,
            options: nil
        ) { (result: Result<UInt, Swift.Error>) in
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
    open func remove(
        _ file: FileType,
        completionHandler: ((Result<UInt, Swift.Error>) -> Void)? = nil
    ) -> Request {
        return remove(
            file,
            options: nil,
            completionHandler: completionHandler
        )
    }
    
    /// Deletes a file instance in the backend.
    @discardableResult
    open func remove(
        _ file: FileType,
        options: Options? = nil,
        completionHandler: ((Result<UInt, Swift.Error>) -> Void)? = nil
    ) -> Request {
        let request = client.networkRequestFactory.buildBlobDeleteFile(
            file,
            options: options
        )
        Promise<UInt> { fulfill, reject in
            request.execute({ (data, response, error) -> Void in
                if let response = response, response.isOK,
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
    open func find(
        _ query: Query = Query(),
        ttl: TTL? = nil,
        completionHandler: FileArrayCompletionHandler? = nil
    ) -> Request {
        return find(
            query,
            ttl: ttl
        ) { (result: Result<[FileType], Swift.Error>) in
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
    open func find(
        _ query: Query = Query(),
        ttl: TTL? = nil,
        completionHandler: ((Result<[FileType], Swift.Error>) -> Void)? = nil
    ) -> Request {
        return find(
            query,
            options: Options(
                ttl: ttl
            ),
            completionHandler: completionHandler
        )
    }
    
    /// Gets a list of files that matches with the query passed by parameter.
    @discardableResult
    open func find(
        _ query: Query = Query(),
        options: Options? = nil,
        completionHandler: ((Result<[FileType], Swift.Error>) -> Void)? = nil
    ) -> Request {
        let request = client.networkRequestFactory.buildBlobQueryFile(
            query,
            options: options
        )
        Promise<[FileType]> { fulfill, reject in
            request.execute { (data, response, error) -> Void in
                if let response = response,
                    response.isOK,
                    let jsonArray = self.client.responseParser.parseArray(data)
                {
                    let files = [FileType](JSONArray: jsonArray)
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
