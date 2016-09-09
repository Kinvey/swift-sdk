//
//  Client.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

private let lockEncryptionKey = NSLock()

/// This class provides a representation of a Kinvey environment holding App ID and App Secret. Please *never* use a Master Secret in a client application.
@objc(__KNVClient)
public class Client: NSObject, Credential {

    /// Shared client instance for simplicity. Use this instance if *you don't need* to handle with multiple Kinvey environments.
    public static let sharedClient = Client()
    
    typealias UserChangedListener = (User?) -> Void
    var userChangedListener: UserChangedListener?
    
    /// It holds the `User` instance after logged in. If this variable is `nil` means that there's no logged user, which is necessary for some calls to in a Kinvey environment.
    public internal(set) var activeUser: User? {
        willSet (newActiveUser) {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            if let activeUser = newActiveUser {
                var json = activeUser.toJSON()
                if var kmd = json[PersistableMetadataKey] as? [String : AnyObject] {
                    kmd.removeValueForKey(Metadata.AuthTokenKey)
                    json[PersistableMetadataKey] = kmd
                }
                userDefaults.setObject(json, forKey: appKey!)
                userDefaults.synchronize()
                
                KCSKeychain2.setKinveyToken(
                    activeUser.metadata?.authtoken,
                    user: activeUser.userId,
                    appKey: appKey,
                    accessible: KCSKeychain2.accessibleStringForDataProtectionLevel(KCSDataProtectionLevel.CompleteUntilFirstLogin) //TODO: using default value for now
                )
                if let authtoken = activeUser.metadata?.authtoken {
                    keychain.authtoken = authtoken
                }
            } else if let appKey = appKey {
                userDefaults.removeObjectForKey(appKey)
                userDefaults.synchronize()
                
                KCSKeychain2.deleteTokensForUser(
                    activeUser?.userId,
                    appKey: appKey
                )
                
                CacheManager(persistenceId: appKey, encryptionKey: encryptionKey).clearAll()
                Keychain(appKey: appKey).removeAll()
                dataStoreInstances.removeAll()
            }
        }
        didSet {
            userChangedListener?(activeUser)
        }
    }
    
    private var keychain: Keychain {
        get {
            return Keychain(appKey: appKey!)
        }
    }
    
    internal var urlSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration()) {
        willSet {
            urlSession.invalidateAndCancel()
        }
    }
    
    /// Holds the App ID for a specific Kinvey environment.
    public private(set) var appKey: String?
    
    /// Holds the App Secret for a specific Kinvey environment.
    public private(set) var appSecret: String?
    
    /// Holds the `Host` for a specific Kinvey environment. The default value is `https://baas.kinvey.com/`
    public private(set) var apiHostName: NSURL
    
    /// Holds the `Authentication Host` for a specific Kinvey environment. The default value is `https://auth.kinvey.com/`
    public private(set) var authHostName: NSURL
    
    /// Cache policy for this client instance.
    public var cachePolicy: NSURLRequestCachePolicy = .UseProtocolCachePolicy
    
    /// Timeout interval for this client instance.
    public var timeoutInterval: NSTimeInterval = 60
    
    /// App version for this client instance.
    public var clientAppVersion: String?
    
    /// Custom request properties for this client instance.
    public var customRequestProperties: [String : String] = [:]
    
    /// The default value for `apiHostName` variable.
    public static let defaultApiHostName = NSURL(string: "https://baas.kinvey.com/")!
    
    /// The default value for `authHostName` variable.
    public static let defaultAuthHostName = NSURL(string: "https://auth.kinvey.com/")!
    
    var networkRequestFactory: RequestFactory!
    var responseParser: ResponseParser!
    
    var encryptionKey: NSData?
    
    /// Set a different schema version to perform migrations in your local cache.
    public private(set) var schemaVersion: CUnsignedLongLong = 0
    
    internal private(set) var cacheManager: CacheManager!
    internal private(set) var syncManager: SyncManager!
    
    /// Use this variable to handle push notifications.
    public private(set) var push: Push!
    
    /// Set a different type if you need a custom `User` class. Extends from `User` allows you to have custom properties in your `User` instances.
    public var userType = User.self
    
    ///Default Value for DataStore tag
    public static let defaultTag = Kinvey.defaultTag
    
    var dataStoreInstances = [DataStoreTypeTag : AnyObject]()
    
    /// Enables logging for any network calls.
    public var logNetworkEnabled = false {
        didSet {
            KCSClient.configureLoggingWithNetworkEnabled(
                logNetworkEnabled,
                debugEnabled: false,
                traceEnabled: false,
                warningEnabled: false,
                errorEnabled: false
            )
        }
    }
    
    /// Stores the MIC API Version to be used in MIC calls 
    public var micApiVersion: String? = "v1"
    
    /// Default constructor. The `initialize` method still need to be called after instanciate a new instance.
    public override init() {
        apiHostName = Client.defaultApiHostName
        authHostName = Client.defaultAuthHostName
        
        super.init()
        
        push = Push(client: self)
        networkRequestFactory = HttpRequestFactory(client: self)
        responseParser = JsonResponseParser(client: self)
    }
    
    /// Constructor that already initialize the client. The `initialize` method is called automatically.
    public convenience init(appKey: String, appSecret: String, apiHostName: NSURL = Client.defaultApiHostName, authHostName: NSURL = Client.defaultAuthHostName) {
        self.init()
        initialize(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName)
    }
    
    /// Initialize a `Client` instance with all the needed parameters and requires a boolean to encrypt or not any store created using this client instance.
    public func initialize(appKey appKey: String, appSecret: String, apiHostName: NSURL = Client.defaultApiHostName, authHostName: NSURL = Client.defaultAuthHostName, encrypted: Bool, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) -> Client {
        precondition((!appKey.isEmpty && !appSecret.isEmpty), "Please provide a valid appKey and appSecret. Your app's key and secret can be found on the Kinvey management console.")

        var encryptionKey: NSData? = nil
        if encrypted {
            lockEncryptionKey.lock()
            
            let keychain = Keychain(appKey: appKey)
            if let key = keychain.defaultEncryptionKey {
                encryptionKey = key
            } else {
                let key = NSMutableData(length: 64)!
                let result = SecRandomCopyBytes(kSecRandomDefault, key.length, unsafeBitCast(key.mutableBytes, UnsafeMutablePointer<UInt8>.self))
                if result == 0 {
                    keychain.defaultEncryptionKey = key
                    encryptionKey = key
                }
            }
            
            lockEncryptionKey.unlock()
        }
        
        return initialize(appKey: appKey, appSecret: appSecret, apiHostName: apiHostName, authHostName: authHostName, encryptionKey: encryptionKey, schemaVersion: schemaVersion, migrationHandler: migrationHandler)
    }
    
    /// Initialize a `Client` instance with all the needed parameters.
    public func initialize(appKey appKey: String, appSecret: String, apiHostName: NSURL = Client.defaultApiHostName, authHostName: NSURL = Client.defaultAuthHostName, encryptionKey: NSData? = nil, schemaVersion: CUnsignedLongLong = 0, migrationHandler: Migration.MigrationHandler? = nil) -> Client {
        precondition((!appKey.isEmpty && !appSecret.isEmpty), "Please provide a valid appKey and appSecret. Your app's key and secret can be found on the Kinvey management console.")
        self.encryptionKey = encryptionKey
        self.schemaVersion = schemaVersion
        cacheManager = CacheManager(persistenceId: appKey, encryptionKey: encryptionKey, schemaVersion: schemaVersion, migrationHandler: migrationHandler)
        syncManager = SyncManager(persistenceId: appKey, encryptionKey: encryptionKey)
        
        var apiHostName = apiHostName
        if let apiHostNameString = apiHostName.absoluteString as String? where apiHostNameString.characters.last == "/" {
            apiHostName = NSURL(string: apiHostNameString.substringToIndex(apiHostNameString.characters.endIndex.predecessor()))!
        }
        var authHostName = authHostName
        if let authHostNameString = authHostName.absoluteString as String? where authHostNameString.characters.last == "/" {
            authHostName = NSURL(string: authHostNameString.substringToIndex(authHostNameString.characters.endIndex.predecessor()))!
        }
        self.apiHostName = apiHostName
        self.authHostName = authHostName
        self.appKey = appKey
        self.appSecret = appSecret
        
        //legacy initilization
        KCSClient.sharedClient().initializeKinveyServiceForAppKey(appKey, withAppSecret: appSecret, usingOptions: nil)
        
        if let json = NSUserDefaults.standardUserDefaults().objectForKey(appKey) as? [String : AnyObject] {
            let user = Mapper<User>().map(json)
            if let user = user, let metadata = user.metadata, let authtoken = keychain.authtoken {
                user.client = self
                metadata.authtoken = authtoken
                activeUser = user
            }
        }
        return self
    }
    
    /// Autorization header used for calls that don't requires a logged `User`.
    public var authorizationHeader: String? {
        get {
            var authorization: String? = nil
            if let appKey = appKey, let appSecret = appSecret {
                let appKeySecret = "\(appKey):\(appSecret)".dataUsingEncoding(NSUTF8StringEncoding)?.base64EncodedStringWithOptions([])
                if let appKeySecret = appKeySecret {
                    authorization = "Basic \(appKeySecret)"
                }
            }
            return authorization
        }
    }

    internal func isInitialized () -> Bool {
        return self.appKey != nil && self.appSecret != nil
    }
    
    internal func filePath(tag: String = defaultTag) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let path = paths.first! as NSString
        var filePath = path.stringByAppendingPathComponent(self.appKey!) as NSString
        
        let fileManager = NSFileManager.defaultManager()
        do {
            let filePath = filePath as String
            if !fileManager.fileExistsAtPath(filePath) {
                try! fileManager.createDirectoryAtPath(filePath, withIntermediateDirectories: true, attributes: nil)
            }
        }
        
        filePath = filePath.stringByAppendingPathComponent("\(tag).realm")
        return filePath as String
    }
}
