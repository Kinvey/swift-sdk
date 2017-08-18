//
//  ResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

internal protocol ResponseParser {
    
    var client: Client { get }
    
    func parse(_ data: Data?) -> JsonDictionary?
    func parseArray(_ data: Data?) -> [JsonDictionary]?
    func parseArray(_ inputStream: InputStream?) -> [JsonDictionary]?
    
    func parse<T: BaseMappable>(_ data: Data?) -> T?
    func parse<T: BaseMappable>(_ data: Data?) -> [T]?
    
    func parseUser<UserType: User>(_ data: Data?) -> UserType?
    func parseUsers<UserType: User>(_ data: Data?) -> [UserType]?

}
