//
//  Realtime.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-05-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import PromiseKit

/// Tells the current status for the realtime connection
public enum RealtimeStatus {
    
    /// Connection is established
    case connected
    
    /// Connection used to be on, but is now off
    case disconnected
    
    /// Connection used to be `disconnected`, but is now on again
    case reconnected
    
    /// Connection used to be on, but is now off for an unexpected reason
    case unexpectedDisconnect
    
}

/// Abstraction layer for Realtime
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
