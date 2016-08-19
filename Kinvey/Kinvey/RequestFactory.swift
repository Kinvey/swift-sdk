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
    func buildUserSocialLogin(authSource: String, authData: [String : AnyObject]) -> HttpRequest
    func buildUserLogin(username username: String, password: String) -> HttpRequest
    func buildUserExists(username username: String) -> HttpRequest
    func buildUserGet(userId userId: String) -> HttpRequest
    func buildUserSave(user user: User) -> HttpRequest
    func buildUserSave(user user: User, newPassword: String?) -> HttpRequest
    func buildUserLookup(user user: User, userQuery: UserQuery) -> HttpRequest
    func buildSendEmailConfirmation(forUsername forUsername: String) -> HttpRequest
    func buildUserResetPassword(usernameOrEmail usernameOrEmail: String) -> HttpRequest
    func buildUserForgotUsername(email email: String) -> HttpRequest
    
    func buildAppDataGetById(collectionName collectionName: String, id: String) -> HttpRequest
    func buildAppDataFindByQuery(collectionName collectionName: String, query: Query) -> HttpRequest
    func buildAppDataSave<T: Persistable>(persistable: T) -> HttpRequest
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
