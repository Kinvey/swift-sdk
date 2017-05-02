//
//  Keychain.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import KeychainAccess

class Keychain {
    
    private let appKey: String?
    private let accessGroup: String?
    private let keychain: KeychainAccess.Keychain
    private let client: Client
    
    init(appKey: String, client: Client) {
        self.appKey = appKey
        self.accessGroup = nil
        self.client = client
        self.keychain = KeychainAccess.Keychain(service: "com.kinvey.Kinvey.\(appKey)").accessibility(.afterFirstUnlockThisDeviceOnly)
    }
    
    init(accessGroup: String, client: Client) {
        self.accessGroup = accessGroup
        self.appKey = nil
        self.client = client
        self.keychain = KeychainAccess.Keychain(service: accessGroup, accessGroup: accessGroup).accessibility(.afterFirstUnlockThisDeviceOnly)
    }
    
    fileprivate static let deviceTokenKey = "deviceToken"
    var deviceToken: Data? {
        get {
            return keychain[data: Keychain.deviceTokenKey]
        }
        set {
            keychain[data: Keychain.deviceTokenKey] = newValue
        }
    }
    
    fileprivate static let userKey = "user"
    var user: User? {
        get {
            if let json = keychain[Keychain.userKey] {
                return client.userType.init(JSONString: json)
            }
            return nil
        }
        set {
            keychain[Keychain.userKey] = newValue?.toJSONString()
        }
    }
    
    fileprivate static let kinveyAuthKey = AuthSource.kinvey.rawValue
    var kinveyAuth: UserAuthToken? {
        get {
            guard let jsonString = keychain[Keychain.kinveyAuthKey] else {
                return nil
            }
            return UserAuthToken(JSONString: jsonString)
        }
        set {
            keychain[Keychain.kinveyAuthKey] = newValue?.toJSONString()
        }
    }
    
    fileprivate static let defaultEncryptionKeyKey = "defaultEncryptionKey"
    var defaultEncryptionKey: Data? {
        get {
            return keychain[data: Keychain.defaultEncryptionKeyKey]
        }
        set {
            keychain[data: Keychain.defaultEncryptionKeyKey] = newValue
        }
    }
    
    func removeAll() throws {
        try keychain.removeAll()
    }
    
}
