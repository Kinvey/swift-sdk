//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

protocol RequestFactory {
    
    func buildUserSignUp(username: String?, password: String?, user: User?, options: Options?) -> HttpRequest
    func buildUserDelete(userId: String, hard: Bool, options: Options?) -> HttpRequest
    
    func buildUserSocialLogin(_ authSource: AuthSource, authData: [String : Any], options: Options?) -> HttpRequest
    func buildUserSocialCreate(_ authSource: AuthSource, authData: [String : Any], options: Options?) -> HttpRequest
    
    func buildUserLogin(username: String, password: String, options: Options?) -> HttpRequest
    func buildUserLogout(user: User, options: Options?) -> HttpRequest
    func buildUserExists(username: String, options: Options?) -> HttpRequest
    func buildUserGet(userId: String, options: Options?) -> HttpRequest
    func buildUserFind(query: Query, options: Options?) -> HttpRequest
    func buildUserSave(user: User, newPassword: String?, options: Options?) -> HttpRequest
    func buildUserLookup(user: User, userQuery: UserQuery, options: Options?) -> HttpRequest
    func buildSendEmailConfirmation(forUsername: String, options: Options?) -> HttpRequest
    func buildUserResetPassword(usernameOrEmail: String, options: Options?) -> HttpRequest
    func buildUserForgotUsername(email: String, options: Options?) -> HttpRequest
    func buildUserMe(options: Options?) -> HttpRequest
    
    func buildUserRegisterRealtime(user: User, deviceId: String, options: Options?) -> HttpRequest
    func buildUserUnregisterRealtime(user: User, deviceId: String, options: Options?) -> HttpRequest
    
    func buildAppDataPing(options: Options?) -> HttpRequest
    func buildAppDataGetById(collectionName: String, id: String, options: Options?) -> HttpRequest
    func buildAppDataFindByQuery(collectionName: String, query: Query, options: Options?) -> HttpRequest
    func buildAppDataCountByQuery(collectionName: String, query: Query?, options: Options?) -> HttpRequest
    func buildAppDataGroup(collectionName: String, keys: [String], initialObject: [String : Any], reduceJSFunction: String, condition: NSPredicate?, options: Options?) -> HttpRequest
    func buildAppDataSave<T: Persistable>(_ persistable: T, options: Options?) -> HttpRequest
    func buildAppDataRemoveByQuery(collectionName: String, query: Query, options: Options?) -> HttpRequest
    func buildAppDataRemoveById(collectionName: String, objectId: String, options: Options?) -> HttpRequest
    func buildAppDataSubscribe(collectionName: String, deviceId: String, options: Options?) -> HttpRequest
    func buildAppDataUnSubscribe(collectionName: String, deviceId: String, options: Options?) -> HttpRequest
    
    func buildPushRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest
    func buildPushUnRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest
    
    func buildBlobUploadFile(_ file: File, options: Options?) -> HttpRequest
    func buildBlobDownloadFile(_ file: File, options: Options?) -> HttpRequest
    func buildBlobDeleteFile(_ file: File, options: Options?) -> HttpRequest
    func buildBlobQueryFile(_ query: Query, options: Options?) -> HttpRequest
    
    func buildCustomEndpoint(_ name: String, options: Options?) -> HttpRequest
    
    func buildOAuthToken(redirectURI: URL, code: String, options: Options?) -> HttpRequest
    
    func buildOAuthGrantAuth(redirectURI: URL, options: Options?) -> HttpRequest
    func buildOAuthGrantAuthenticate(redirectURI: URL, tempLoginUri: URL, username: String, password: String, options: Options?) -> HttpRequest
    func buildOAuthGrantRefreshToken(refreshToken: String, options: Options?) -> HttpRequest
    
    func buildLiveStreamGrantAccess(streamName: String, userId: String, acl: LiveStreamAcl, options: Options?) -> HttpRequest
    func buildLiveStreamPublish(streamName: String, userId: String, options: Options?) -> HttpRequest
    func buildLiveStreamSubscribe(streamName: String, userId: String, deviceId: String, options: Options?) -> HttpRequest
    func buildLiveStreamUnsubscribe(streamName: String, userId: String, deviceId: String, options: Options?) -> HttpRequest
    
}

/// Allow override custom values whenever the default value is not desired.
public struct Options {
    
    /// Custom `Client` instance
    public var client: Client?
    
    /// Custom `URLSession` instance
    public var urlSession: URLSession?
    
    /// Custom `authServiceId` value used for MIC
    public var authServiceId: String?
    
    /// Custom `TTL` value used for cases where time-to-live value is present
    public var ttl: TTL?
    
    /// Enables / disables delta set
    public var deltaSet: Bool?
    
    /// Custom read policy for read operations
    public var readPolicy: ReadPolicy?
    
    /// Custom write policy for write operations
    public var writePolicy: WritePolicy?
    
    /// Custom timeout interval for network requests
    public var timeout: TimeInterval?
    
    /// App version for this client instance.
    public var clientAppVersion: String?
    
    /// Custom request properties for this client instance.
    public var customRequestProperties: [String : Any]?
    
    /**
     Constructor that takes the values that need to be specified and assign
     default values for all the other properties
     */
    public init(
        client: Client? = nil,
        urlSession: URLSession? = nil,
        authServiceId: String? = nil,
        ttl: TTL? = nil,
        deltaSet: Bool? = nil,
        readPolicy: ReadPolicy? = nil,
        writePolicy: WritePolicy? = nil,
        timeout: TimeInterval? = nil,
        clientAppVersion: String? = nil,
        customRequestProperties: [String : Any]? = nil
    ) {
        self.client = client
        self.urlSession = urlSession
        self.authServiceId = authServiceId
        self.ttl = ttl
        self.deltaSet = deltaSet
        self.readPolicy = readPolicy
        self.writePolicy = writePolicy
        self.timeout = timeout
        self.clientAppVersion = clientAppVersion
        self.customRequestProperties = customRequestProperties
    }
    
}
