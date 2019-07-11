//
//  PendingOperation.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public protocol PendingOperation {
    
    var requestId: String { get }
    var collectionName: String { get }
    var objectId: String? { get }
    var objectIds: AnyRandomAccessCollection<String>? { get }
    var requestIds: AnyRandomAccessCollection<String>? { get }
    
    func buildRequest() -> URLRequest
    
}

public struct AnyPendingOperation: PendingOperation {
    
    private let _requestId: () -> String
    private let _collectionName: () -> String
    private let _objectId: () -> String?
    private let _objectIds: () -> AnyRandomAccessCollection<String>?
    private let _requestIds: () -> AnyRandomAccessCollection<String>?
    private let _buildRequest: () -> URLRequest
    
    init<T: PendingOperation>(_ pendingOperation: T) {
        _requestId = { pendingOperation.requestId }
        _collectionName = { pendingOperation.collectionName }
        _objectId = { pendingOperation.objectId }
        _objectIds = { pendingOperation.objectIds }
        _requestIds = { pendingOperation.requestIds }
        _buildRequest = pendingOperation.buildRequest
    }
    
    public var requestId: String {
        return _requestId()
    }
    
    public var collectionName: String {
        return _collectionName()
    }
    
    public var objectId: String? {
        return _objectId()
    }
    
    public var objectIds: AnyRandomAccessCollection<String>? {
        return _objectIds()
    }
    
    public var requestIds: AnyRandomAccessCollection<String>? {
        return _requestIds()
    }
    
    public func buildRequest() -> URLRequest {
        return _buildRequest()
    }
    
}
