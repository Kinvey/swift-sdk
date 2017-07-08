//
//  Realtime.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit

/// Tells the current status for the realtime connection
public enum RealtimeStatus {
    
    /// Connection is stablished
    case connected
    
    /// Connection used to be on, but is now off
    case disconnected
    
    /// Connection used to be `disconnected`, but is now on again
    case reconnected
    
    /// Connection used to be on, but is now off for an unexpected reason
    case unexpectedDisconnect
    
}

protocol RealtimeRouter {
    
    func subscribe(
        channel: String,
        context: AnyHashable,
        onNext: @escaping (Any?) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    )
    
    func unsubscribe(channel: String, context: AnyHashable)
    
    func publish(
        channel: String,
        message: Any,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)?
    )
    
}

/**
 Class that creates a live stream connection to be used in a peer-to-peer
 communication
 */
public class LiveStream<Type: BaseMappable> {
    
    private let name: String
    private let client: Client
    
    private var substreamChannelNameMap = [String : String]()
    
    fileprivate let uuid = UUID()
    
    /**
     Constructor that takes the name of the stream and an (optional) `Client`
     instance
     */
    public init(name: String, client: Client = sharedClient) {
        self.name = name
        self.client = client
    }
    
    private var userPromise: Promise<User> {
        return Promise<User> { fulfill, reject in
            if let user = client.activeUser {
                fulfill(user)
            } else {
                reject(Error.invalidOperation(description: "Active User not found"))
            }
        }
    }
    
    private var realtimeRouterPromise: Promise<(User, RealtimeRouter)> {
        return userPromise.then { activeUser in
            return Promise<(User, RealtimeRouter)> { fulfill, reject in
                if let realtimeRouter = activeUser.realtimeRouter {
                    fulfill(activeUser, realtimeRouter)
                } else {
                    reject(Error.invalidOperation(description: "Active User not register for realtime"))
                }
            }
        }
    }
    
    /// Grant access to a user for the `LiveStream`
    @discardableResult
    public func grantStreamAccess(userId: String, acl: LiveStreamAcl, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) -> Request {
        let request = client.networkRequestFactory.buildLiveStreamGrantAccess(streamName: name, userId: userId, acl: acl)
        Promise<Void> { fulfill, reject in
            request.execute() { (data, response, error) in
                if let response = response, response.isOK, let _ = data {
                    fulfill()
                } else {
                    reject(buildError(data, response, error, self.client))
                }
            }
        }.then {
            completionHandler?(.success())
        }.catch { error in
            completionHandler?(.failure(error))
        }
        return request
    }
    
    /// Sends a message to an specific user
    public func send(userId: String, message: Type, retry: Bool = true, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, realtimeRouter in
            return Promise<(RealtimeRouter, String)> { fulfill, reject in
                if let channelName = self.substreamChannelNameMap[userId] {
                    fulfill(realtimeRouter, channelName)
                } else {
                    let request = self.client.networkRequestFactory.buildLiveStreamPublish(streamName: self.name, userId: userId)
                    request.execute() { (data, response, error) in
                        if let response = response,
                            response.isOK,
                            let data = data,
                            let jsonObject = try? JSONSerialization.jsonObject(with: data),
                            let jsonDict = jsonObject as? [String : String],
                            let substreamChannelName = jsonDict["substreamChannelName"]
                        {
                            self.substreamChannelNameMap[userId] = substreamChannelName
                            fulfill(realtimeRouter, substreamChannelName)
                        } else {
                            reject(buildError(data, response, error, self.client))
                        }
                    }
                }
            }
        }.then { realtimeRouter, channelName in
            return Promise<Void> { fulfill, reject in
                realtimeRouter.publish(channel: channelName, message: message.toJSON()) {
                    switch $0 {
                    case .success:
                        fulfill()
                    case .failure(let error):
                        if retry, let error = error as? Kinvey.Error {
                            switch error {
                            case .forbidden:
                                self.substreamChannelNameMap.removeValue(forKey: userId)
                                self.send(userId: userId, message: message, retry: false) {
                                    switch $0 {
                                    case .success:
                                        fulfill()
                                    case .failure(let error):
                                        reject(error)
                                    }
                                }
                            default:
                                reject(error)
                            }
                        } else {
                            reject(error)
                        }
                    }
                }
            }
        }.then {
            completionHandler?(.success())
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    /// Start listening messages sent to the current active user
    public func listen(
        listening: @escaping () -> Void,
        onNext: @escaping (Type) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    ) {
        realtimeRouterPromise.then { activeUser, realtimeRouter in
            self.follow(userId: activeUser.userId, following: listening, onNext: onNext, onStatus: onStatus, onError: onError)
        }.catch { error in
            onError(error)
        }
    }
    
    /// /// Stop listening messages sent to the current active user
    public func stopListening(completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, _ in
            self.unfollow(userId: activeUser.userId, completionHandler: completionHandler)
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    /// Sends a message to the current active user
    public func post(message: Type, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, _ in
            self.send(userId: activeUser.userId, message: message, completionHandler: completionHandler)
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    /// Start listening messages sent to an specific user
    public func follow(
        userId: String,
        following: @escaping () -> Void,
        onNext: @escaping (Type) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    ) {
        realtimeRouterPromise.then { activeUser, realtimeRouter in
            return Promise<(RealtimeRouter, String)> { fulfill, reject in
                if let channelName = self.substreamChannelNameMap[userId] {
                    fulfill(realtimeRouter, channelName)
                } else {
                    let request = self.client.networkRequestFactory.buildLiveStreamSubscribe(streamName: self.name, userId: userId, deviceId: deviceId)
                    request.execute() { (data, response, error) in
                        if let response = response,
                            response.isOK,
                            let data = data,
                            let jsonObject = try? JSONSerialization.jsonObject(with: data),
                            let jsonDict = jsonObject as? [String : String],
                            let substreamChannelName = jsonDict["substreamChannelName"]
                        {
                            self.substreamChannelNameMap[userId] = substreamChannelName
                            fulfill(realtimeRouter, substreamChannelName)
                        } else {
                            reject(buildError(data, response, error, self.client))
                        }
                    }
                }
            }
        }.then { (realtimeRouter, channelName) -> Void in
            realtimeRouter.subscribe(
                channel: channelName,
                context: self,
                onNext: { msg in
                    if let dict = msg as? [String : Any], let obj = Type(JSON: dict) {
                        onNext(obj)
                    }
                },
                onStatus: onStatus,
                onError: onError
            )
        }.then {
            following()
        }.catch { error in
            onError(error)
        }
    }
    
    /// Stop listening messages sent to an specific user
    public func unfollow(userId: String, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, realtimeRouter in
            return Promise<RealtimeRouter> { fulfill, reject in
                let request = self.client.networkRequestFactory.buildLiveStreamUnsubscribe(streamName: self.name, userId: userId, deviceId: deviceId)
                request.execute() { (data, response, error) in
                    if let response = response, response.isOK {
                        fulfill(realtimeRouter)
                    } else {
                        reject(buildError(data, response, error, self.client))
                    }
                }
            }
        }.then { realtimeRouter -> Void in
            if let channel = self.substreamChannelNameMap[userId] {
                realtimeRouter.unsubscribe(channel: channel, context: self)
            }
        }.then {
            completionHandler?(.success())
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
}

/// Access Control Level (Acl) for `LiveStream` objects
public struct LiveStreamAcl: StaticMappable {
    
    /// List of `userId`s that are allowed to subscribe
    public var subscribers = [String]()
    
    /// List of `userId`s that are allowed to publish
    public var publishers = [String]()
    
    /// Group Acl
    public var groups = LiveStreamAclGroups()
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return LiveStreamAcl()
    }
    
    public mutating func mapping(map: Map) {
        subscribers <- map["subscribe"]
        publishers <- map["publish"]
        groups <- map["groups"]
    }
    
}

/// Group Access Control Level (Group Acl) for `LiveStream` objects
public struct LiveStreamAclGroups: StaticMappable {
    
    /// List of groups that are allowed to publish
    public var publishers = [String]()
    
    /// List of groups that are allowed to subscribe
    public var subscribers = [String]()
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return LiveStreamAclGroups()
    }
    
    public mutating func mapping(map: Map) {
        subscribers <- map["subscribe"]
        publishers <- map["publish"]
    }
    
}

/**
 Makes the `LiveStream` to conforms to `Hashable`, so they can be stored in
 Dictionaries for example
 */
extension LiveStream: Hashable {
    
    public var hashValue: Int {
        return uuid.hashValue
    }
    
    public static func ==(lhs: LiveStream<Type>, rhs: LiveStream<Type>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}
