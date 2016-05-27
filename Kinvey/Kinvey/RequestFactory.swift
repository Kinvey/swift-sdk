//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

protocol RequestFactory {
    
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
    func buildAppDataRemoveById(collectionName collectionName: String, objectId: String) -> HttpRequest
    
    func buildPushRegisterDevice(deviceToken: NSData) -> HttpRequest
    func buildPushUnRegisterDevice(deviceToken: NSData) -> HttpRequest
    
    func buildBlobUploadFile(file: File) -> HttpRequest
    func buildBlobDownloadFile(file: File, ttl: TTL?) -> HttpRequest
    func buildBlobDeleteFile(file: File) -> HttpRequest
    func buildBlobQueryFile(query: Query, ttl: TTL?) -> HttpRequest
    
    func buildCustomEndpoint(name: String) -> HttpRequest
    
}

extension RequestFactory {
    
    func toJson(jsonObject: JsonDictionary) -> NSData {
        var jsonObject = jsonObject
        if !NSJSONSerialization.isValidJSONObject(jsonObject) {
            for keyPair in jsonObject {
                if let valueTransformer = ValueTransformer.valueTransformer(fromClass: keyPair.1.dynamicType, toClass: NSString.self) {
                    jsonObject[keyPair.0] = valueTransformer.transformValue(keyPair.1, destinationType: String.self)
                } else if let persistable = keyPair.1 as? Persistable {
                    if let toJson = persistable.toJson {
                        jsonObject[keyPair.0] = toJson()
                    } else {
                        jsonObject[keyPair.0] = persistable._toJson()
                    }
                } else if let acl = keyPair.1 as? Acl {
                    jsonObject[keyPair.0] = acl.toJson()
                } else if !EntitySchema.isTypeSupported(keyPair.1) {
                    if let jsonObj = keyPair.1 as? JsonObject {
                        if let toJson = jsonObj.toJson {
                            jsonObject[keyPair.0] = toJson()
                        } else {
                            jsonObject[keyPair.0] = jsonObj._toJson()
                        }
                    } else if let coding = keyPair.1 as? NSCoding {
                        let data = NSMutableData()
                        let coder = NSKeyedArchiver(forWritingWithMutableData: data)
                        coding.encodeWithCoder(coder)
                        coder.finishEncoding()
                        jsonObject[keyPair.0] = data.base64EncodedStringWithOptions([])
                    } else {
                        jsonObject.removeValueForKey(keyPair.0)
                    }
                }
            }
        }
        
        return try! NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
    }
    
}
