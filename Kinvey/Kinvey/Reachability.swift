//
//  Reachability.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-02-05.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

/// Reachability helper object. Use to test for existence of connection or changes in connectivity. Note that a `true` isReachable doesn't necessarily mean that the conncetion will succeed, just that it is possible.
public class Reachability {
    
    /** Use to check the reachability to the network */
    public class func reachabilityForInternetConnection() -> Reachability {
        return Reachability(reachability: KCSReachability.reachabilityForInternetConnection())
    }
    
    /** Use to check the reachability of a particular host name. */
    public class func reachabilityWithHostName(hostName: String) -> Reachability {
        return Reachability(reachability: KCSReachability(hostName: hostName))
    }
    
    /**
     The main direct test of reachability.
     Always true before reachability is initialized (async).
     - Returns: Bool: `true` if a network connection is available.
     */
    public func isReachable() -> Bool {
        return reachability.isReachable()
    }
    
    /**
     Test if the connection is cellular
     - Returns: Bool: `true` if 3G, EDGE, LTE etc
     */
    public func isReachableViaWWAN() -> Bool {
        return reachability.isReachableViaWWAN()
    }
    
    /**
     Test if connection is wifi.
     - Returns: Bool: `true` if connection is wifi.
     */
    public func isReachableViaWiFi() -> Bool {
        return reachability.isReachableViaWiFi()
    }
    
    private let reachability: KCSReachability
    
    private init(reachability: KCSReachability) {
        self.reachability = reachability
    }
    
}
