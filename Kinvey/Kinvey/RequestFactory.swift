//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

protocol RequestFactory {
    
    func buildUserSignUp<Result>(
        username: String?,
        password: String?,
        user: User?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserDelete<Result>(
        userId: String,
        hard: Bool,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserSocialLogin(_ authSource: AuthSource, authData: [String : Any], options: Options?) -> HttpRequest<Any>
    func buildUserSocialCreate(_ authSource: AuthSource, authData: [String : Any], options: Options?) -> HttpRequest<Any>
    
    func buildUserLogin<Result>(
        username: String,
        password: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserLogout<Result>(
        user: User,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserExists<Result>(
        username: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserGet<Result>(
        userId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserFind<Result>(
        query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserSave<Result>(
        user: User,
        newPassword: String?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserLookup<Result>(
        user: User,
        userQuery: UserQuery,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildSendEmailConfirmation<Result>(
        forUsername: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserResetPassword<Result>(
        usernameOrEmail: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserForgotUsername<Result>(
        email: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserMe<Result>(
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserRegisterRealtime<Result>(
        user: User,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildUserUnregisterRealtime<Result>(
        user: User,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataPing<Result>(
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataGetById<Result>(
        collectionName: String,
        id: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataFindByQuery(collectionName: String, query: Query, options: Options?) -> HttpRequest<Any>
    
    func buildAppDataFindByQueryDeltaSet(collectionName: String, query: Query, sinceDate: Date, options: Options?) -> HttpRequest<Any>
    
    func buildAppDataCountByQuery<Result>(
        collectionName: String,
        query: Query?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataGroup<Result>(
        collectionName: String,
        keys: [String],
        initialObject: [String : Any],
        reduceJSFunction: String,
        condition: NSPredicate?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataSave<T: Persistable, Result>(
        _ persistable: T,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataRemoveByQuery<Result>(
        collectionName: String,
        query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataRemoveById<Result>(
        collectionName: String,
        objectId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataSubscribe<Result>(
        collectionName: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildAppDataUnSubscribe<Result>(
        collectionName: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildPushRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest<Any>
    func buildPushUnRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest<Any>
    
    func buildBlobUploadFile(_ file: File, options: Options?) -> HttpRequest<Any>
    
    func buildBlobDownloadFile<Result>(
        _ file: File,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildBlobDeleteFile<Result>(
        _ file: File,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildBlobQueryFile<Result>(
        _ query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildCustomEndpoint<Result>(
        _ name: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildOAuthToken(redirectURI: URL, code: String, options: Options?) -> HttpRequest<Any>
    func buildOAuthToken(username: String, password: String, options: Options?) -> HttpRequest<Any>
    
    func buildOAuthGrantAuth(redirectURI: URL, options: Options?) -> HttpRequest<Any>
    func buildOAuthGrantAuthenticate(redirectURI: URL, tempLoginUri: URL, username: String, password: String, options: Options?) -> HttpRequest<Any>
    func buildOAuthGrantRefreshToken(refreshToken: String, options: Options?) -> HttpRequest<Any>
    
    func buildLiveStreamAccess<Result>(
        streamName: String,
        userId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildLiveStreamPublish(streamName: String, userId: String, options: Options?) -> HttpRequest<Any>
    
    func buildLiveStreamSubscribe<Result>(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
    func buildLiveStreamUnsubscribe<Result>(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result>
    
}
