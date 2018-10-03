//
//  PubNubRealtimeRouter.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import PubNub
import PromiseKit

protocol PubNubType {
    
    static func clientWithConfiguration(_ configuration: PNConfiguration) -> Self
    func addListener(_ listener: PNObjectEventListener)
    func subscribeToChannelGroups(_ groups: [String], withPresence shouldObservePresence: Bool)
    func publish(_ message: Any, toChannel channel: String, withCompletion block: PNPublishCompletionBlock?)
    
}

extension PubNub: PubNubType {
}

class PubNubRealtimeRouter: NSObject, RealtimeRouter {
    
    let user: User
    let subscribeKey: String
    let publishKey: String
    let userChannelGroup: String
    
    private let pubNub: PubNubType
    
    typealias RealtimeCallbackTuple = (onNext: (Any?) -> Void, onStatus: (RealtimeStatus) -> Void, onError: (Swift.Error) -> Void)
    
    private var callbacksMap = [String : [AnyHashable : RealtimeCallbackTuple]]()
    private let queue = DispatchQueue(label: "Kinvey Realtime")
    
    convenience init(user: User, subscribeKey: String, publishKey: String, userChannelGroup: String) {
        self.init(user: user, subscribeKey: subscribeKey, publishKey: publishKey, userChannelGroup: userChannelGroup, pubNubType: PubNub.self)
    }
    
    init<PubNub: PubNubType>(user: User, subscribeKey: String, publishKey: String, userChannelGroup: String, pubNubType: PubNub.Type) {
        self.user = user
        self.subscribeKey = subscribeKey
        self.publishKey = publishKey
        self.userChannelGroup = userChannelGroup
        
        let configuration = PNConfiguration(publishKey: publishKey, subscribeKey: subscribeKey)
        configuration.stripMobilePayload = false
        configuration.authKey = user.metadata?.authtoken
        pubNub = pubNubType.clientWithConfiguration(configuration)
        super.init()
        pubNub.addListener(self)
        pubNub.subscribeToChannelGroups([userChannelGroup], withPresence: false)
    }
    
    fileprivate subscript(channel: String) -> [AnyHashable : RealtimeCallbackTuple] {
        get {
            var callbacks = callbacksMap[channel]
            if callbacks == nil {
                callbacks = [:]
                callbacksMap[channel] = callbacks
            }
            return callbacks!
        }
        set {
            callbacksMap[channel] = newValue
        }
    }
    
    func subscribe(
        channel: String,
        context: AnyHashable,
        onNext: @escaping (Any?) -> Void,
        onStatus: @escaping (RealtimeStatus) -> Void,
        onError: @escaping (Swift.Error) -> Void
    ) {
        queue.sync {
            let handler = RealtimeCallbackTuple(
                onNext: onNext,
                onStatus: onStatus,
                onError: onError
            )
            self[channel][context] = handler
        }
    }
    
    func unsubscribe(channel: String, context: AnyHashable) {
        queue.sync {
            var callbacks = self[channel]
            callbacks.removeValue(forKey: context)
            self[channel] = callbacks
        }
    }
    
    func fireOnStatus(status: RealtimeStatus) {
        for (_, callbacks) in callbacksMap {
            for (_, callbackTuple) in callbacks {
                callbackTuple.onStatus(status)
            }
        }
    }
    
    func publish(
        channel: String,
        message: Any,
        completionHandler: ((Result<Void, Swift.Error>) -> Void)?
    ) {
        Promise<Void> { resolver in
            pubNub.publish(message, toChannel: channel) { (publishStatus) in
                if publishStatus.isError {
                    switch publishStatus.statusCode {
                    case 403:
                        resolver.reject(Error.forbidden(description: publishStatus.errorData.information))
                    default:
                        resolver.reject(Error.unknownError(httpResponse: nil, data: nil, error: publishStatus.errorData.information))
                    }
                } else {
                    resolver.fulfill(())
                }
            }
        }.done {
            completionHandler?(.success($0))
        }.catch { error in
            completionHandler?(.failure(error))
        }
    }
    
}

extension PubNubRealtimeRouter: PNObjectEventListener {
    
    func client(_ client: PubNub, didReceiveMessage message: PNMessageResult) {
        for (_, callback) in self[message.data.channel] {
            callback.onNext(message.data.message)
        }
    }
    
    func client(_ client: PubNub, didReceive status: PNStatus) {
        switch status.category {
        case .PNConnectedCategory:
            fireOnStatus(status: .connected)
        case .PNDisconnectedCategory:
            fireOnStatus(status: .disconnected)
        case .PNReconnectedCategory:
            fireOnStatus(status: .reconnected)
        case .PNUnexpectedDisconnectCategory:
            fireOnStatus(status: .unexpectedDisconnect)
        default:
            if status.isError, let errorStatus = status as? PNErrorStatus {
                let callbacks = errorStatus.errorData.channels.flatMap {
                    self[$0].map { $1 }
                }
                let error = Error.unknownError(httpResponse: nil, data: nil, error: errorStatus.errorData.information)
                for callback in callbacks {
                    callback.onError(error)
                }
            }
        }
    }
    
}
