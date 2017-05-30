//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

protocol RequestFactory {
    
    func buildUserSignUp(username: String?, password: String?, user: User?) -> HttpRequest
    func buildUserDelete(userId: String, hard: Bool) -> HttpRequest
    
    func buildUserSocialLogin(_ authSource: AuthSource, authData: [String : Any]) -> HttpRequest
    func buildUserSocialCreate(_ authSource: AuthSource, authData: [String : Any]) -> HttpRequest
    
    func buildUserLogin(username: String, password: String) -> HttpRequest
    func buildUserExists(username: String) -> HttpRequest
    func buildUserGet(userId: String) -> HttpRequest
    func buildUserSave(user: User, newPassword: String?) -> HttpRequest
    func buildUserLookup(user: User, userQuery: UserQuery) -> HttpRequest
    func buildSendEmailConfirmation(forUsername: String) -> HttpRequest
    func buildUserResetPassword(usernameOrEmail: String) -> HttpRequest
    func buildUserForgotUsername(email: String) -> HttpRequest
    
    func buildAppDataPing() -> HttpRequest
    func buildAppDataGetById(collectionName: String, id: String) -> HttpRequest
    func buildAppDataFindByQuery(collectionName: String, query: Query) -> HttpRequest
    func buildAppDataCountByQuery(collectionName: String, query: Query?) -> HttpRequest
    func buildAppDataGroup(collectionName: String, keys: [String], initialObject: [String : Any], reduceJSFunction: String, condition: NSPredicate?) -> HttpRequest
    func buildAppDataSave<T: Persistable>(_ persistable: T) -> HttpRequest
    func buildAppDataRemoveByQuery(collectionName: String, query: Query) -> HttpRequest
    func buildAppDataRemoveById(collectionName: String, objectId: String) -> HttpRequest
    
    func buildPushRegisterDevice(_ deviceToken: Data) -> HttpRequest
    func buildPushUnRegisterDevice(_ deviceToken: Data) -> HttpRequest
    
    func buildBlobUploadFile(_ file: File) -> HttpRequest
    func buildBlobDownloadFile(_ file: File, ttl: TTL?) -> HttpRequest
    func buildBlobDeleteFile(_ file: File) -> HttpRequest
    func buildBlobQueryFile(_ query: Query, ttl: TTL?) -> HttpRequest
    
    func buildCustomEndpoint(_ name: String) -> HttpRequest
    
    func buildOAuthToken(redirectURI: URL, code: String, clientId: String?) -> HttpRequest
    
    func buildOAuthGrantAuth(redirectURI: URL, clientId: String?) -> HttpRequest
    func buildOAuthGrantAuthenticate(redirectURI: URL, clientId: String?, tempLoginUri: URL, username: String, password: String) -> HttpRequest
    func buildOAuthGrantRefreshToken(refreshToken: String, clientId: String?) -> HttpRequest
    
}
