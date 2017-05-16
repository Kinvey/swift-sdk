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
    private let client: Client?
    internal let keychain: KeychainAccess.Keychain
    
    init() {
        self.appKey = nil
        self.accessGroup = nil
        self.client = nil
        self.keychain = KeychainAccess.Keychain().accessibility(.afterFirstUnlockThisDeviceOnly)
    }
    
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
    
    enum Key: String {
        
        case deviceToken = "deviceToken"
        case user = "user"
        case clientId = "client_id"
        case kinveyAuth = "kinveyAuth"
        case defaultEncryptionKey = "defaultEncryptionKey"
        case deviceId = "deviceId"
        
    }
    
    var deviceToken: Data? {
        get {
            return keychain[data: .deviceToken]
        }
        set {
            keychain[data: .deviceToken] = newValue
        }
    }
    
    var user: User? {
        get {
            return client?.responseParser.parseUser(keychain[.user]?.data(using: .utf8))
        }
        set {
            keychain[.user] = newValue?.toJSONString()
        }
    }
    
    var clientId: String? {
        get {
            return keychain[.clientId]
        }
        set {
            keychain[.clientId] = newValue
        }
    }
    
    var kinveyAuth: [String : Any]? {
        get {
            if let jsonString = keychain[.kinveyAuth],
                let data = jsonString.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: data)
            {
                return jsonObject as? JsonDictionary
            }
            return nil
        }
        set {
            if let newValue = newValue,
                let data = try? JSONSerialization.data(withJSONObject: newValue)
            {
                keychain[.kinveyAuth] = String(data: data, encoding: .utf8)
            } else {
                keychain[.kinveyAuth] = nil
            }
        }
    }
    
    var defaultEncryptionKey: Data? {
        get {
            return keychain[data: .defaultEncryptionKey]
        }
        set {
            keychain[data: .defaultEncryptionKey] = newValue
        }
    }
    
    func removeAll() throws {
        try keychain.removeAll()
    }
    
}

extension KeychainAccess.Keychain {
    
    subscript(key: Keychain.Key) -> String? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue
        }
    }
    
    subscript(data key: Keychain.Key) -> Data? {
        get {
            return self[data: key.rawValue]
        }
        set {
            self[data: key.rawValue] = newValue
        }
    }
    
}
