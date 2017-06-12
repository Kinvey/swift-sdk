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

public enum RealtimeStatus {
    
    case connected, disconnected, reconnected, unexpectedDisconnect
    
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

public class LiveStream<Type: BaseMappable> {
    
    private let name: String
    private let client: Client
    
    private var substreamChannelNameMap = [String : String]()
    
    fileprivate let uuid = UUID()
    
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
    
    public func send(userId: String, message: Type, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
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
                        reject(error)
                    }
                }
            }
        }.then {
            completionHandler?(.success())
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    public func listen(
        onNext: @escaping (Type) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    ) {
        realtimeRouterPromise.then { activeUser, realtimeRouter in
            self.follow(userId: activeUser.userId, onNext: onNext, onStatus: onStatus, onError: onError)
        }.catch { error in
            onError(error)
        }
    }
    
    public func stopListening(completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, _ in
            self.unfollow(userId: activeUser.userId, completionHandler: completionHandler)
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    public func post(message: Type, completionHandler: ((Result<Void, Swift.Error>) -> Void)? = nil) {
        realtimeRouterPromise.then { activeUser, _ in
            self.send(userId: activeUser.userId, message: message, completionHandler: completionHandler)
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
    public func follow(
        userId: String,
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
        }.then { realtimeRouter, channelName in
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
        }.catch { error in
            onError(error)
        }
    }
    
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

public struct LiveStreamAcl: StaticMappable {
    
    public var subscribers = [String]()
    public var publishers = [String]()
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

public struct LiveStreamAclGroups: StaticMappable {
    
    public var publishers = [String]()
    public var subscribers = [String]()
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        return LiveStreamAclGroups()
    }
    
    public mutating func mapping(map: Map) {
        subscribers <- map["subscribe"]
        publishers <- map["publish"]
    }
    
}

extension LiveStream: Hashable {
    
    public var hashValue: Int {
        return uuid.hashValue
    }
    
    public static func ==(lhs: LiveStream<Type>, rhs: LiveStream<Type>) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
}