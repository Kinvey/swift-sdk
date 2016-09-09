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
    
    let appKey: String
    private let keychain: KeychainAccess.Keychain
    
    init(appKey: String) {
        self.appKey = appKey
        self.keychain = KeychainAccess.Keychain(service: "com.kinvey.Kinvey.\(appKey)").accessibility(.AfterFirstUnlockThisDeviceOnly)
    }
    
    private static let deviceTokenKey = "deviceToken"
    var deviceToken: NSData? {
        get {
            return keychain[data: Keychain.deviceTokenKey]
        }
        set {
            keychain[data: Keychain.deviceTokenKey] = newValue
        }
    }
    
    private static let authtokenKey = "authtoken"
    var authtoken: String? {
        get {
            return keychain[Keychain.authtokenKey]
        }
        set {
            keychain[Keychain.authtokenKey] = newValue
        }
    }
    
    private static let defaultEncryptionKeyKey = "defaultEncryptionKey"
    var defaultEncryptionKey: NSData? {
        get {
            return keychain[data: Keychain.defaultEncryptionKeyKey]
        }
        set {
            keychain[data: Keychain.defaultEncryptionKeyKey] = newValue
        }
    }
    
    func removeAll() {
        try! keychain.removeAll()
    }
    
}
