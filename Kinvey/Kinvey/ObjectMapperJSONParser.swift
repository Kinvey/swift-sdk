//
//  JsonResponseParser.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

#if canImport(os)
import os
#endif

class ObjectMapperJSONParser: JSONParser {
    
    let client: Client
    
    init(client: Client) {
        self.client = client
    }
    
    func parseDictionary(from data: Data) throws -> JsonDictionary {
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? JsonDictionary else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return dictionary
    }
    
    func parseDictionaries(from data: Data) throws -> [JsonDictionary] {
        #if canImport(os)
        let logName: StaticString = "Parse Dictionaries"
        if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
            os_signpost(.begin, log: osLog, name: logName)
        }
        defer {
            if #available(iOS 12.0, OSX 10.14, tvOS 12.0, watchOS 5.0, *) {
                os_signpost(.end, log: osLog, name: logName)
            }
        }
        #endif
        guard let dictionaries = try JSONSerialization.jsonObject(with: data) as? [JsonDictionary] else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return dictionaries
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseObject<T>(_ type: T.Type, from dictionary: [String : Any]) throws -> T {
        guard let mappableType = T.self as? BaseMappable.Type,
            let result = mappableType.init(JSON: dictionary) as? T
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return result
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseObject<T>(_ type: T.Type, from data: Data) throws -> T {
        guard let mappableType = T.self as? BaseMappable.Type,
            let json: JsonDictionary = try? parseDictionary(from: data),
            let object = mappableType.init(JSON: json) as? T
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return object
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseObjects<T>(_ type: T.Type, from data: Data) throws -> [T] {
        guard let mappableType = T.self as? BaseMappable.Type else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        let jsonArray = try parseDictionaries(from: data)
        return jsonArray.compactMap({ mappableType.init(JSON: $0) as? T })
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    fileprivate func parse<UserType: User>(_ userType: UserType.Type, from json: JsonDictionary) -> UserType? {
        let map = Map(mappingType: .fromJSON, JSON: json)
        let user: UserType? = userType.init(map: map)
        user?.mapping(map: map)
        return user
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseUser<UserType: User>(_ userType: UserType.Type, from data: Data) throws -> UserType {
        guard data.count > 0,
            let json = try JSONSerialization.jsonObject(with: data) as? JsonDictionary,
            let user = parse(client.userType, from: json) as? UserType
        else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: [User.CodingKeys.userId], debugDescription: "\(User.CodingKeys.userId.rawValue) is required"))
        }
        return user
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseUser<UserType>(_ userType: UserType.Type, from dictionary: [String : Any]) throws -> UserType where UserType : User {
        guard let result = userType.init(JSON: dictionary) else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return result
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func parseUsers<UserType: User>(_ userType: UserType.Type, from data: Data) throws -> [UserType] {
        guard data.count > 0,
            let result = try? JSONSerialization.jsonObject(with: data) as? [JsonDictionary],
            let jsonArray = result
        else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Parser Error"))
        }
        return jsonArray.compactMap { parse(client.userType, from: $0) as? UserType }
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func toJSON<UserType>(_ user: UserType) -> [String : Any] where UserType : User {
        return user.toJSON()
    }
    
    @available(*, deprecated: 3.18.0, message: "Please use Swift.Codable instead")
    func toJSON<T>(_ object: T) -> [String : Any] {
        guard let object = object as? BaseMappable else {
            return [:]
        }
        return object.toJSON()
    }

}
