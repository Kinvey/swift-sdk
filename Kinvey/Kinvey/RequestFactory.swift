//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol RequestFactory {
    
    func buildUserSignUp(username username: String?, password: String?) -> HttpRequest
    func buildUserDelete(userId userId: String, hard: Bool) -> HttpRequest
    func buildUserLogin(username username: String, password: String) -> HttpRequest
    func buildUserExists(username username: String) -> HttpRequest
    func buildUserGet(userId userId: String) -> HttpRequest
    func buildUserSave(user user: User) -> HttpRequest
    
    func buildAppDataGetById(collectionName collectionName: String, id: String) -> HttpRequest
    func buildAppDataFindByQuery(collectionName collectionName: String, query: Query) -> HttpRequest
    func buildAppDataSave<T: Persistable where T: NSObject>(collectionName collectionName: String, persistable: T) -> HttpRequest
    func buildAppDataRemoveByQuery(collectionName collectionName: String, query: Query) -> HttpRequest
    
    func buildPushRegisterDevice(deviceToken: NSData) -> HttpRequest
    func buildPushUnRegisterDevice(deviceToken: NSData) -> HttpRequest
    
    func buildBlobUploadFile(file: File) -> HttpRequest
    func buildBlobDownloadFile(file: File, ttl: TTL?) -> HttpRequest
    func buildBlobDeleteFile(file: File) -> HttpRequest
    func buildBlobQueryFile(query: Query, ttl: TTL?) -> HttpRequest
    
}
