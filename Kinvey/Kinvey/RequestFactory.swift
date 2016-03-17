//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

//@objc(KNVRequestFactory)
public protocol RequestFactory {
    
    func buildUserSignUp(username username: String?, password: String?) -> HttpRequest
    func buildUserDelete(userId userId: String, hard: Bool) -> HttpRequest
    func buildUserLogin(username username: String, password: String) -> HttpRequest
    func buildUserExists(username username: String) -> HttpRequest
    func buildUserGet(userId userId: String) -> HttpRequest
    func buildUserSave(user user: User) -> HttpRequest
    func buildUserResetPassword(usernameOrEmail usernameOrEmail: String) -> HttpRequest
    func buildUserForgotUsername(email email: String) -> HttpRequest
    
    func buildAppDataGetById(collectionName collectionName: String, id: String) -> HttpRequest
    func buildAppDataFindByQuery(collectionName collectionName: String, query: Query, fields: Set<String>?) -> HttpRequest
    func buildAppDataSave(persistable: Persistable) -> HttpRequest
    func buildAppDataRemoveByQuery(collectionName collectionName: String, query: Query) -> HttpRequest
    
    func buildPushRegisterDevice(deviceToken: NSData) -> HttpRequest
    func buildPushUnRegisterDevice(deviceToken: NSData) -> HttpRequest
    
    func buildBlobUploadFile(file: File) -> HttpRequest
    func buildBlobDownloadFile(file: File, ttl: TTL?) -> HttpRequest
    func buildBlobDeleteFile(file: File) -> HttpRequest
    func buildBlobQueryFile(query: Query, ttl: TTL?) -> HttpRequest
    
}

extension RequestFactory {
    
    func toJson(var jsonObject: JsonDictionary) -> NSData {
        if !NSJSONSerialization.isValidJSONObject(jsonObject) {
            for keyPair in jsonObject {
                if let valueTransformer = ValueTransformer.valueTransformer(fromClass: keyPair.1.dynamicType, toClass: NSString.self) {
                    jsonObject[keyPair.0] = valueTransformer.transformValue(keyPair.1, destinationType: String.self)
                }
            }
        }
        
        return try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
    }
    
}
