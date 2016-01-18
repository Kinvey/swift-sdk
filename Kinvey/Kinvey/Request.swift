//
//  Request.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-07.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public typealias DataResponseCompletionHandler = (NSData?, Response?, NSError?) -> Void

public protocol Request {
    
    var endpoint: Endpoint { get }
    
    var executing: Bool { get }
    var canceled: Bool { get }
    
    func execute(completionHandler: DataResponseCompletionHandler?)
    func cancel()
    
//    var method: HttpMethod { get set }
//    var pathname: String { get set }
//    var flags: String { get set }
//    var data: String { get set }
//    var auth: String { get set }
//    var client: String { get set }
//    var dataPolicy: String { get set }
//    var writePolicy: String { get set }
//    var responseType: String { get set }
//    var timeout: String { get set }
//    var ttl: String { get set }
//    var headers: String { get set }
    
    //var requestProperties : RequestProperties {get set}
   
//    func addHeaders(headers: [String : String]) -> Void
//    func setHeader(name: String, value: String) -> Void
//    func getHeader(name: String) -> Void
//    func removeHeader(name: String) -> Void
//    func clearHeaders() -> Void
    
    // ??? Talk to Tejas
//    func addMetadada() -> Void

}
