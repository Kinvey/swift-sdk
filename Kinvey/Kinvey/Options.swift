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
    public private(set) var maxSizePerResultSet: Int?
    
    private func validate(maxSizePerResultSet value: Int?) throws {
        if let value = value, value <= 0 {
            throw Error.invalidOperation(description: "maxSizePerResultSet must be greater than 0 (zero)")
        }
    }
    
    /**
     Constructor that takes the values that need to be specified and assign
     default values for all the other properties
     */
    public init(
        _ options: Options? = nil,
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
    ) throws {
        self.client = client ?? options?.client
        self.urlSession = urlSession ?? options?.urlSession
        self.authServiceId = authServiceId ?? options?.authServiceId
        self.ttl = ttl ?? options?.ttl
        self.deltaSet = deltaSet ?? options?.deltaSet
        self.readPolicy = readPolicy ?? options?.readPolicy
        self.writePolicy = writePolicy ?? options?.writePolicy
        self.timeout = timeout ?? options?.timeout
        self.clientAppVersion = clientAppVersion ?? options?.clientAppVersion
        self.customRequestProperties = customRequestProperties ?? options?.customRequestProperties
        self.maxSizePerResultSet = maxSizePerResultSet ?? options?.maxSizePerResultSet
        try validate(maxSizePerResultSet: self.maxSizePerResultSet)
    }
    
    init(specific: Options?, general: Options?) throws {
        self.client = specific?.client ?? general?.client
        self.urlSession = specific?.urlSession ?? general?.urlSession
        self.authServiceId = specific?.authServiceId ?? general?.authServiceId
        self.ttl = specific?.ttl ?? general?.ttl
        self.deltaSet = specific?.deltaSet ?? general?.deltaSet
        self.readPolicy = specific?.readPolicy ?? general?.readPolicy
        self.writePolicy = specific?.writePolicy ?? general?.writePolicy
        self.timeout = specific?.timeout ?? general?.timeout
        self.clientAppVersion = specific?.clientAppVersion ?? general?.clientAppVersion
        self.customRequestProperties = specific?.customRequestProperties ?? general?.customRequestProperties
        self.maxSizePerResultSet = specific?.maxSizePerResultSet ?? general?.maxSizePerResultSet
        try validate(maxSizePerResultSet: self.maxSizePerResultSet)
    }
    
}

extension Options {
    
    /**
     Constructor that takes the values that need to be specified and assign
     default values for all the other properties
     */
    public init(_ block: (inout Options) -> Void) {
        block(&self)
    }
    
}
