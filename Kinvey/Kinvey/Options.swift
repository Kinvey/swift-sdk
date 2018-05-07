//
//  Options.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2018-01-11.
//  Copyright © 2018 Kinvey. All rights reserved.
//

import Foundation

/// Allow override custom values whenever the default value is not desired.
public struct Options {
    
    /// Custom `Client` instance
    public var client: Client?
    
    /// Custom `URLSession` instance
    public var urlSession: URLSession?
    
    /// Custom `authServiceId` value used for MIC
    public var authServiceId: String?
    
    /// Custom `TTL` value used for cases where time-to-live value is present
    public var ttl: TTL?
    
    /// Enables / disables delta set
    public var deltaSet: Bool?
    
    /// Custom read policy for read operations
    public var readPolicy: ReadPolicy?
    
    /// Custom write policy for write operations
    public var writePolicy: WritePolicy?
    
    /// Custom timeout interval for network requests
    public var timeout: TimeInterval?
    
    /// App version for this client instance.
    public var clientAppVersion: String?
    
    /// Custom request properties for this client instance.
    public var customRequestProperties: [String : Any]?
    
    /// Maximum size per result set coming from the backend. Default to 10k records.
    public var maxSizePerResultSet: Int? {
        willSet {
            if let newValue = newValue, newValue <= 0 {
                fatalError("maxSizePerResultSet must be greater than 0 (zero)")
            }
        }
    }
    
    /**
     Constructor that takes the values that need to be specified and assign
     default values for all the other properties
     */
    public init(_ block: (inout Options) -> Void) {
        block(&self)
    }
    
    /**
     Constructor that takes the values that need to be specified and assign
     default values for all the other properties
     */
    public init(
        client: Client? = nil,
        urlSession: URLSession? = nil,
        authServiceId: String? = nil,
        ttl: TTL? = nil,
        deltaSet: Bool? = nil,
        readPolicy: ReadPolicy? = nil,
        writePolicy: WritePolicy? = nil,
        timeout: TimeInterval? = nil,
        clientAppVersion: String? = nil,
        customRequestProperties: [String : Any]? = nil,
        maxSizePerResultSet: Int? = nil
    ) {
        self.client = client
        self.urlSession = urlSession
        self.authServiceId = authServiceId
        self.ttl = ttl
        self.deltaSet = deltaSet
        self.readPolicy = readPolicy
        self.writePolicy = writePolicy
        self.timeout = timeout
        self.clientAppVersion = clientAppVersion
        self.customRequestProperties = customRequestProperties
        self.maxSizePerResultSet = maxSizePerResultSet
    }
    
}
