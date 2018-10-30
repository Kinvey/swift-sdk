//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

private let lockEncryptionKey = NSLock()

/// This class provides a representation of a Kinvey environment holding App ID and App Secret. Please *never* use a Master Secret in a client application.
open class Client: Credential {

    /// Shared client instance for simplicity. Use this instance if *you don't need* to handle with multiple Kinvey environments.
    public static let sharedClient = Client()
    
    typealias UserChangedListener = (User?) -> Void
    var userChangedListener: UserChangedListener?
    
    /// It holds the `User` instance after logged in. If this variable is `nil` means that there's no logged user, which is necessary for some calls to in a Kinvey environment.
    open internal(set) var activeUser: User? {
        willSet (newActiveUser) {
            if let activeUser = newActiveUser {
                keychain.user = activeUser
                if let sharedKeychain = sharedKeychain, let socialIdentity = activeUser.socialIdentity, let kinveyAuth = socialIdentity.kinvey {
                    sharedKeychain.kinveyAuth = kinveyAuth
                }
            } else if let appKey = appKey {
                CacheManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?).clearAll()
                try! Keychain(appKey: appKey, client: self).removeAll()
                if let sharedKeychain = sharedKeychain {
                    try! sharedKeychain.removeAll()
                }
            } else {
                if let sharedKeychain = sharedKeychain {
                    try! sharedKeychain.removeAll()
                }
            }
        }
        didSet {
            userChangedListener?(activeUser)
        }
    }
    
    internal var clientId: String? {
        willSet {
            keychain.clientId = clientId
        }
    }
    
    private var accessGroup: String?
    
    internal var keychain: Keychain {
        return Keychain(appKey: appKey!, client: self)
    }
    
    private var sharedKeychain: Keychain? {
        if let accessGroup = accessGroup {
            return Keychain(accessGroup: accessGroup, client: self)
        }
        return nil
    }
    
    internal static let urlSessionConfiguration = URLSessionConfiguration.default
    
    internal var urlSession = URLSession(configuration: urlSessionConfiguration) {
        willSet {
            urlSession.invalidateAndCancel()
        }
    }
    
    /// Holds the App ID for a specific Kinvey environment.
    open fileprivate(set) var appKey: String?
    
    /// Holds the App Secret for a specific Kinvey environment.
    open fileprivate(set) var appSecret: String?
    
    /// Holds the `Host` for a specific Kinvey environment. The default value is `https://baas.kinvey.com/`
    open private(set) var apiHostName: URL
    
    /// Holds the `Authentication Host` for a specific Kinvey environment. The default value is `https://auth.kinvey.com/`
    open private(set) var authHostName: URL
    
    /// Cache policy for this client instance.
    open var cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
    
    /**
     Hold default optional values for all calls made by this `Client` instance
     */
    open var options: Options?
    
    /// The default value for `apiHostName` variable.
    public static let defaultApiHostName = URL(string: "https://baas.kinvey.com/")!
    
    /// The default value for `authHostName` variable.
    public static let defaultAuthHostName = URL(string: "https://auth.kinvey.com/")!
    
    var networkRequestFactory: RequestFactory!
    var jsonParser: JSONParser!
    
    var encryptionKey: Data?
    
    /// Set a different schema version to perform migrations in your local cache.
    open fileprivate(set) var schemaVersion: CUnsignedLongLong?
    
    internal fileprivate(set) var cacheManager: CacheManager!
    internal fileprivate(set) var syncManager: SyncManager!
    
    /// Use this variable to handle push notifications.
    open fileprivate(set) var push: Push!
    
    /// Set a different type if you need a custom `User` class. Extends from `User` allows you to have custom properties in your `User` instances.
    open var userType = User.self
    
    ///Default Value for DataStore tag
    public static let defaultTag = Kinvey.defaultTag
    
    /// Enables logging for any network calls.
    open var logNetworkEnabled = false
    
    /// Stores the MIC API Version to be used in MIC calls 
    open var micApiVersion: MICApiVersion? = .v3
    
    internal let refreshTokenDispatchGroup = DispatchGroup()
    internal var refreshingToken = false
    
    /// Default constructor. The `initialize` method still need to be called after instanciate a new instance.
    public init() {
        apiHostName = Client.defaultApiHostName
        authHostName = Client.defaultAuthHostName
        
        push = Push(client: self)
        networkRequestFactory = HttpRequestFactory(client: self)
        self.jsonParser = DefaultJSONParser(client: self)
    }
    
    /// Constructor that already initialize the client. The `initialize` method is called automatically.
    public convenience init<U: User>(
        appKey: String,
        appSecret: String,
        instanceId: String,
        accessGroup: String? = nil,
        schema: Schema? = nil,
        options: Options? = nil,
        completionHandler: ((Result<U?, Swift.Error>) -> Void)? = nil
    ) {
        self.init()
        initialize(
            appKey: appKey,
            appSecret: appSecret,
            instanceId: instanceId,
            accessGroup: accessGroup,
            schema: schema,
            options: options
        ) { (result: Result<U?, Swift.Error>) in
            completionHandler?(result)
        }
    }
    
    /// Constructor that already initialize the client. The `initialize` method is called automatically.
    public convenience init<U: User>(
        appKey: String,
        appSecret: String,
        accessGroup: String? = nil,
        apiHostName: URL = Client.defaultApiHostName,
        authHostName: URL = Client.defaultAuthHostName,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        options: Options? = nil,
        completionHandler: ((Result<U?, Swift.Error>) -> Void)? = nil
    ) {
        self.init()
        initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            schema: schema,
            compactCacheOnLaunch: compactCacheOnLaunch,
            options: options
        ) { (result: Result<U?, Swift.Error>) in
            completionHandler?(result)
        }
    }
    
    private func validateInitialize(appKey: String, appSecret: String) throws {
        guard Thread.isMainThread else {
            throw Error.invalidOperation(description: "Client.initialize() must be called in the main thread.")
        }
        guard schemaVersion == nil else {
            throw Error.invalidOperation(description: "Client instance already initialized.")
        }
        if appKey.isEmpty || appSecret.isEmpty {
            throw Error.invalidOperation(description: "Please provide a valid appKey and appSecret. Your app's key and secret can be found on the Kinvey management console.")
        }
    }
    
    /// Initialize a `Client` instance with all the needed parameters and requires a boolean to encrypt or not any store created using this client instance.
    @available(*, deprecated: 3.17.0, message: "Please use Client.initialize(appKey:appSecret:accessGroup:apiHostName:authHostName:encrypted:schema:completionHandler:(Result<User?, Swift.Error>) -> Void")
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        accessGroup: String? = nil,
        apiHostName: URL = Client.defaultApiHostName,
        authHostName: URL = Client.defaultAuthHostName,
        encrypted: Bool,
        schema: Schema? = nil,
        completionHandler: @escaping User.UserHandler<U>
    ) {
        initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            encrypted: encrypted,
            schema: schema
        ) { (result: Result<U?, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler(user, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    private func encryptionKey(appKey: String) -> Data? {
        lockEncryptionKey.lock()
        
        var encryptionKey: Data? = nil
        let keychain = Keychain(appKey: appKey, client: self)
        if let key = keychain.defaultEncryptionKey {
            encryptionKey = key as Data
        } else {
            let numberOfBytes = 64
            var bytes = [UInt8](repeating: 0, count: numberOfBytes)
            let result = SecRandomCopyBytes(kSecRandomDefault, numberOfBytes, &bytes)
            if result == 0 {
                let key = Data(bytes: bytes)
                keychain.defaultEncryptionKey = key
                encryptionKey = key
            }
        }
        
        lockEncryptionKey.unlock()
        return encryptionKey
    }
    
    /// Initialize a `Client` instance with all the needed parameters and requires a boolean to encrypt or not any store created using this client instance.
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        accessGroup: String? = nil,
        apiHostName: URL = Client.defaultApiHostName,
        authHostName: URL = Client.defaultAuthHostName,
        encrypted: Bool,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        options: Options? = nil,
        completionHandler: @escaping (Result<U?, Swift.Error>) -> Void
    ) {
        do {
            try validateInitialize(appKey: appKey, appSecret: appSecret)
        } catch {
            completionHandler(.failure(error))
            return
        }

        let encryptionKey = encrypted ? self.encryptionKey(appKey: appKey) : nil
        
        initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            encryptionKey: encryptionKey,
            schema: Schema(version: schema?.version ?? 0, migrationHandler: schema?.migrationHandler),
            compactCacheOnLaunch: compactCacheOnLaunch,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /// Initialize a `Client` instance with all the needed parameters.
    @available(*, deprecated: 3.17.0, message: "Please use Client.initialize(appKey:appSecret:accessGroup:apiHostName:authHostName:encryptionKey:schema:completionHandler:(Result<U?, Swift.Error>) -> Void) instead")
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        accessGroup: String? = nil,
        apiHostName: URL = Client.defaultApiHostName,
        authHostName: URL = Client.defaultAuthHostName,
        encryptionKey: Data? = nil,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        completionHandler: @escaping User.UserHandler<U>
    ) {
        initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            encryptionKey: encryptionKey,
            schema: schema,
            compactCacheOnLaunch: compactCacheOnLaunch
        ) { (result: Result<U?, Swift.Error>) in
            switch result {
            case .success(let user):
                completionHandler(user, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Initialize a `Client` instance.
     - parameters:
     - appKey: `App Key` value from Kinvey Console
     - appSecret: `App Secret` value from Kinvey Console
     - instanceId: Prefix value of `Host URL` from Kinvey Console. eg: my-instance if the Host URL looks like my-instance-baas.kinvey.com
     - accessGroup: Access Group for Keychain
     - encrypted: Enable encryption for cache
     - schema: Migration Schema to be used in case a migration is required
     - options: Custom Options to be used instead of default values
     - completionHandler: Completion Handler async call
     */
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        instanceId: String,
        accessGroup: String? = nil,
        encrypted: Bool,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        options: Options? = nil,
        completionHandler: @escaping (Result<U?, Swift.Error>) -> Void
    ) {
        do {
            try validateInitialize(appKey: appKey, appSecret: appSecret)
        } catch {
            completionHandler(.failure(error))
            return
        }
        
        let (apiHostNameString, authHostNameString) = hostNames(instanceId: instanceId)
        guard let apiHostName = URL(string: apiHostNameString) else {
            completionHandler(.failure(Error.invalidOperation(description: "Invalid InstanceID: \(instanceId). \(apiHostNameString) is not a valid URL.")))
            return
        }
        guard let authHostName = URL(string: authHostNameString) else {
            completionHandler(.failure(Error.invalidOperation(description: "Invalid InstanceID: \(instanceId). \(authHostNameString) is not a valid URL.")))
            return
        }
        
        let encryptionKey = encrypted ? self.encryptionKey(appKey: appKey) : nil
        
        return initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            encryptionKey: encryptionKey,
            schema: schema,
            compactCacheOnLaunch: compactCacheOnLaunch,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    /**
     Initialize a `Client` instance.
     - parameters:
       - appKey: `App Key` value from Kinvey Console
       - appSecret: `App Secret` value from Kinvey Console
       - instanceId: Prefix value of `Host URL` from Kinvey Console. eg: my-instance if the Host URL looks like my-instance-baas.kinvey.com
       - accessGroup: Access Group for Keychain
       - encryptionKey: Encryption Key for cache
       - schema: Migration Schema to be used in case a migration is required
       - options: Custom Options to be used instead of default values
       - completionHandler: Completion Handler async call
    */
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        instanceId: String,
        accessGroup: String? = nil,
        encryptionKey: Data? = nil,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        options: Options? = nil,
        completionHandler: @escaping (Result<U?, Swift.Error>) -> Void
    ) {
        let (apiHostNameString, authHostNameString) = hostNames(instanceId: instanceId)
        guard let apiHostName = URL(string: apiHostNameString) else {
            completionHandler(.failure(Error.invalidOperation(description: "Invalid InstanceID: \(instanceId). \(apiHostNameString) is not a valid URL.")))
            return
        }
        guard let authHostName = URL(string: authHostNameString) else {
            completionHandler(.failure(Error.invalidOperation(description: "Invalid InstanceID: \(instanceId). \(authHostNameString) is not a valid URL.")))
            return
        }
        
        return initialize(
            appKey: appKey,
            appSecret: appSecret,
            accessGroup: accessGroup,
            apiHostName: apiHostName,
            authHostName: authHostName,
            encryptionKey: encryptionKey,
            schema: schema,
            compactCacheOnLaunch: compactCacheOnLaunch,
            options: options,
            completionHandler: completionHandler
        )
    }
    
    private func hostNames(instanceId: String) -> (apiHostName: String, authHostName: String) {
        return (apiHostName: "https://\(instanceId)-baas.kinvey.com", authHostName: "https://\(instanceId)-auth.kinvey.com")
    }
    
    /// Initialize a `Client` instance with all the needed parameters.
    open func initialize<U: User>(
        appKey: String,
        appSecret: String,
        accessGroup: String? = nil,
        apiHostName: URL = Client.defaultApiHostName,
        authHostName: URL = Client.defaultAuthHostName,
        encryptionKey: Data? = nil,
        schema: Schema? = nil,
        compactCacheOnLaunch: Bool = true,
        options: Options? = nil,
        completionHandler: @escaping (Result<U?, Swift.Error>) -> Void
    ) {
        do {
            try validateInitialize(appKey: appKey, appSecret: appSecret)
        } catch {
            completionHandler(.failure(error))
            return
        }
        
        self.encryptionKey = encryptionKey
        let schemaVersion = schema?.version ?? 0
        self.schemaVersion = schemaVersion
        self.options = options
        
        Migration.performMigration(
            persistenceId: appKey,
            encryptionKey: encryptionKey,
            schemaVersion: schemaVersion,
            migrationHandler: schema?.migrationHandler,
            compactCacheOnLaunch: compactCacheOnLaunch
        )
        
        cacheManager = CacheManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?, schemaVersion: schemaVersion)
        syncManager = SyncManager(persistenceId: appKey, encryptionKey: encryptionKey as Data?, schemaVersion: schemaVersion)
        
        var apiHostName = apiHostName
        if let apiHostNameString = apiHostName.absoluteString as String?, apiHostNameString.last == "/" {
            apiHostName = URL(string: String(apiHostNameString.dropLast()))!
        }
        var authHostName = authHostName
        if let authHostNameString = authHostName.absoluteString as String?, authHostNameString.last == "/" {
            authHostName = URL(string: String(authHostNameString.dropLast()))!
        }
        self.apiHostName = apiHostName
        self.authHostName = authHostName
        self.appKey = appKey
        self.appSecret = appSecret
        self.accessGroup = accessGroup
        
        let userDefaults = UserDefaults.standard
        if let json = userDefaults.dictionary(forKey: appKey) {
            keychain.user = try? jsonParser.parseUser(userType, from: json)
            userDefaults.removeObject(forKey: appKey)
            userDefaults.synchronize()
        }
        
        if let user = keychain.user {
            user.client = self
            activeUser = user
            clientId = keychain.clientId
            let customUser = user as! U
            completionHandler(.success(customUser))
        } else if let kinveyAuth = sharedKeychain?.kinveyAuth {
            User.login(authSource: .kinvey, kinveyAuth, options: try! Options(client: self)) { (result: Result<U, Swift.Error>) in
                switch result {
                case .success(let user):
                    completionHandler(.success(user))
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        } else {
            completionHandler(.success(nil))
        }
    }
    
    /// Autorization header used for calls that don't requires a logged `User`.
    open var authorizationHeader: String? {
        var authorization: String? = nil
        if let appKey = appKey, let appSecret = appSecret {
            let appKeySecret = "\(appKey):\(appSecret)".data(using: String.Encoding.utf8)?.base64EncodedString()
            if let appKeySecret = appKeySecret {
                authorization = "Basic \(appKeySecret)"
            }
        }
        return authorization
    }

    internal func isInitialized() -> Bool {
        return self.appKey != nil && self.appSecret != nil
    }
    
    internal func validate() throws {
        guard isInitialized() else {
            throw Error.clientNotInitialized
        }
    }
    
    internal class func fileURL(appKey: String, tag: String = defaultTag) -> URL {
        let path = cacheBasePath as NSString
        var filePath = URL(fileURLWithPath: path.appendingPathComponent(appKey))
        filePath.appendPathComponent("\(tag).realm")
        return filePath
    }
    
    internal func fileURL(_ tag: String = defaultTag) -> URL {
        return Client.fileURL(appKey: self.appKey!, tag: tag)
    }
    
    /**
     Check if the `appKey` and `appSecret` properties are correct doing a ping
     call to the server.
     */
    @discardableResult
    @available(*, deprecated: 3.17.1, message: "Please use Client.ping(completionHandler:) instead")
    public func ping(completionHandler: @escaping (EnvironmentInfo?, Swift.Error?) -> Void) -> AnyRequest<Result<EnvironmentInfo, Swift.Error>> {
        return ping() { (result: Result<EnvironmentInfo, Swift.Error>) in
            switch result {
            case .success(let envInfo):
                completionHandler(envInfo, nil)
            case .failure(let error):
                completionHandler(nil, error)
            }
        }
    }
    
    /**
     Checks connectivity to your backend. A successful response returns a
     summary of your backend environment and confirms that the app can talk to
     the backend.
     */
    @discardableResult
    public func ping(completionHandler: @escaping (Result<EnvironmentInfo, Swift.Error>) -> Void) -> AnyRequest<Result<EnvironmentInfo, Swift.Error>> {
        guard let _ = appKey, let _ = appSecret else {
            return errorRequest(error: Error.invalidOperation(description: "Please initialize your client calling the initialize() method before call ping()"), completionHandler: completionHandler)
        }
        let request = networkRequestFactory.buildAppDataPing(
            options: options,
            resultType: Result<EnvironmentInfo, Swift.Error>.self
        )
        Promise<EnvironmentInfo> { resolver in
            request.execute() { data, response, error in
                if let response = response,
                    response.isOK,
                    let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data),
                    let result = json as? [String : String],
                    let environmentInfo = EnvironmentInfo(JSON: result)
                {
                    resolver.fulfill(environmentInfo)
                } else {
                    resolver.reject(buildError(data, response, error, self))
                }
            }
        }.done {
            completionHandler(.success($0))
        }.catch {
            completionHandler(.failure($0))
        }
        return AnyRequest(request)
    }
}

/// Environment Information for a specific `appKey` and `appSecret`
public struct EnvironmentInfo {
    
    /// Version of the backend
    public let version: String
    
    /// Hello message from Kinvey
    public let kinvey: String
    
    /// Application Name
    public let appName: String
    
    /// Environment Name
    public let environmentName: String
    
}

@available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
extension EnvironmentInfo : StaticMappable {
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        guard let version: String = map["version"].value(),
            let kinvey: String = map["kinvey"].value(),
            let appName: String = map["appName"].value(),
            let environmentName: String = map["environmentName"].value()
            else {
                return nil
        }
        return EnvironmentInfo(
            version: version,
            kinvey: kinvey,
            appName: appName,
            environmentName: environmentName
        )
    }
    
    public mutating func mapping(map: Map) {
    }
    
}
