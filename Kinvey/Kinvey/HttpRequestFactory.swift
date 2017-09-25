//
//  HttpNetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

class HttpRequestFactory: RequestFactory {
    
    let client: Client
    
    required init(client: Client) {
        self.client = client
    }
    
    typealias CompletionHandler = (Data?, URLResponse?, NSError?) -> Void
    
    func buildUserSignUp(
        username: String? = nil,
        password: String? = nil,
        user: User? = nil,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.user(client: client, query: nil),
            options: options
        )
        
        var bodyObject = JsonDictionary()
        if let username = username {
            bodyObject["username"] = username
        }
        if let password = password {
            bodyObject["password"] = password
        }
        if let user = user {
            bodyObject += user.toJSON()
        }
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserDelete(
        userId: String,
        hard: Bool,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.userDelete(client: client, userId: userId, hard: hard),
            credential: client.activeUser,
            options: options
        )

        //FIXME: make it configurable
        request.request.setValue("2", forHTTPHeaderField: "X-Kinvey-API-Version")
        return request
    }
    
    func buildUserSocial(
        _ authSource: AuthSource,
        authData: [String : Any],
        endpoint: Endpoint,
        options: Options?
    ) -> HttpRequest {
        let bodyObject = [
            "_socialIdentity" : [
                authSource.rawValue : authData
            ]
        ]
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: endpoint,
            body: Body.json(json: bodyObject),
            options: options
        )
        return request
    }
    
    func buildUserSocialLogin(
        _ authSource: AuthSource,
        authData: [String : Any],
        options: Options?
    ) -> HttpRequest {
        return buildUserSocial(
            authSource,
            authData: authData,
            endpoint: Endpoint.userLogin(client: client),
            options: options
        )
    }
    
    func buildUserSocialCreate(
        _ authSource: AuthSource,
        authData: [String : Any],
        options: Options?
    ) -> HttpRequest {
        return buildUserSocial(
            authSource,
            authData: authData,
            endpoint: Endpoint.user(client: client, query: nil),
            options: options
        )
    }
    
    func buildUserLogin(
        username: String,
        password: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userLogin(client: client),
            options: options
        )
        
        let bodyObject = [
            "username" : username,
            "password" : password
        ]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserLogout(
        user: User,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userLogout(client: client),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserExists(
        username: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userExistsByUsername(client: client),
            options: options
        )
        request.request.httpMethod = "POST"
        
        let bodyObject = ["username" : username]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserGet(
        userId: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.userById(client: client, userId: userId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserFind(
        query: Query,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.user(client: client, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserSave(
        user: User,
        newPassword: String?,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .put,
            endpoint: Endpoint.userById(client: client, userId: user.userId),
            credential: client.activeUser,
            options: options
        )
        var bodyObject = user.toJSON()
        
        if let newPassword = newPassword {
            bodyObject["password"] = newPassword
        }
        
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserLookup(
        user: User,
        userQuery: UserQuery,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userLookup(client: client),
            credential: client.activeUser,
            options: options
        )
        let bodyObject = userQuery.toJSON()
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserResetPassword(
        usernameOrEmail: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userResetPassword(usernameOrEmail: usernameOrEmail, client: client),
            credential: client,
            options: options
        )
        return request
    }
    
    func buildUserForgotUsername(
        email: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.userForgotUsername(client: client),
            credential: client,
            options: options
        )
        let bodyObject = ["email" : email]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserMe(
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.userMe(client: client),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataPing(options: Options?) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.appDataPing(client: client),
            options: options
        )
        return request
    }
    
    func buildAppDataGetById(
        collectionName: String,
        id: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.appDataById(client: client, collectionName: collectionName, id: id),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataFindByQuery(
        collectionName: String,
        query: Query,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query.isEmpty ? nil : query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataCountByQuery(
        collectionName: String,
        query: Query?,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            endpoint: Endpoint.appDataCount(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataGroup(
        collectionName: String,
        keys: [String],
        initialObject: [String : Any],
        reduceJSFunction: String,
        condition: NSPredicate?,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.appDataGroup(client: client, collectionName: collectionName),
            credential: client.activeUser,
            options: options
        )
        var json: [String : Any] = [
            "key" : keys,
            "initial" : initialObject,
            "reduce" : reduceJSFunction
        ]
        if let condition = condition {
            json["condition"] = condition.mongoDBQuery
        }
        request.setBody(json: json)
        return request
    }
    
    func buildAppDataSave<T: Persistable>(
        _ persistable: T,
        options: Options?
    ) -> HttpRequest {
        let collectionName = T.collectionName()
        var bodyObject = persistable.toJSON()
        let objId = bodyObject[Entity.Key.entityId] as? String
        let isNewObj = objId == nil || objId!.hasPrefix(ObjectIdTmpPrefix)
        let request = HttpRequest(
            httpMethod: isNewObj ? .post : .put,
            endpoint: isNewObj ? Endpoint.appData(client: client, collectionName: collectionName) : Endpoint.appDataById(client: client, collectionName: collectionName, id: objId!),
            credential: client.activeUser,
            options: options
        )
        
        if (isNewObj) {
            bodyObject[Entity.Key.entityId] = nil
        }
        
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildAppDataRemoveByQuery(
        collectionName: String,
        query: Query,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataRemoveById(
        collectionName: String,
        objectId: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.appDataById(client: client, collectionName: collectionName, id: objectId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    private func buildPushDevice(
        _ deviceToken: Data,
        options: Options?,
        client: Client,
        endpoint: Endpoint
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: endpoint,
            credential: client.activeUser,
            options: options
        )
        
        let bodyObject = [
            "platform" : "ios",
            "deviceId" : deviceToken.hexString()
        ]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildPushRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest {
        let client = options?.client ?? self.client
        return buildPushDevice(
            deviceToken,
            options: options,
            client: client,
            endpoint: Endpoint.pushRegisterDevice(client: client)
        )
    }
    
    func buildPushUnRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest {
        let client = options?.client ?? self.client
        return buildPushDevice(
            deviceToken,
            options: options,
            client: client,
            endpoint: Endpoint.pushUnRegisterDevice(client: client)
        )
    }
    
    func buildBlobUploadFile(
        _ file: File,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: file.fileId == nil ? .post : .put,
            endpoint: Endpoint.blobUpload(
                client: client,
                fileId: file.fileId,
                tls: true
            ),
            credential: client.activeUser,
            options: options
        )
        
        let bodyObject = file.toJSON()
        request.request.setValue(file.mimeType ?? "application/octet-stream", forHTTPHeaderField: "X-Kinvey-Content-Type")
        request.setBody(json: bodyObject)
        return request
    }
    
    fileprivate func ttlInSeconds(_ ttl: TTL?) -> UInt? {
        if let (value, unit) = ttl {
            return UInt(unit.toTimeInterval(value))
        }
        return nil
    }
    
    func buildBlobDownloadFile(
        _ file: File,
        options: Options?
    ) -> HttpRequest {
        let ttl = options?.ttl
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.blobDownload(
                client: client,
                fileId: file.fileId!,
                query: nil,
                tls: true,
                ttlInSeconds: ttlInSeconds(ttl)
            ),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildBlobDeleteFile(
        _ file: File,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .delete,
            endpoint: Endpoint.blobById(client: client, fileId: file.fileId!),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildBlobQueryFile(
        _ query: Query,
        options: Options?
    ) -> HttpRequest {
        let ttl = options?.ttl
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.blobDownload(
                client: client,
                fileId: nil,
                query: query,
                tls: true,
                ttlInSeconds: ttlInSeconds(ttl)
            ),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildCustomEndpoint(
        _ name: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.customEndpooint(client: client, name: name),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildSendEmailConfirmation(
        forUsername username: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.sendEmailConfirmation(client: client, username: username),
            credential: client,
            options: options
        )
        return request
    }
    
    func set(_ params: inout [String : String], clientId: String?) {
        if let appKey = client.appKey {
            if let clientId = clientId {
                params["client_id"] = "\(appKey).\(clientId)"
            } else {
                params["client_id"] = appKey
            }
        }
    }
    
    func buildOAuthToken(
        redirectURI: URL,
        code: String,
        options: Options?
    ) -> HttpRequest {
        var params = [
            "grant_type" : "authorization_code",
            "redirect_uri" : redirectURI.absoluteString,
            "code" : code
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.oauthToken(client: client),
            credential: client,
            body: Body.formUrlEncoded(params: params),
            options: options
        )
        return request
    }
    
    func buildOAuthGrantAuth(
        redirectURI: URL,
        options: Options?
    ) -> HttpRequest {
        var json = [
            "redirect_uri" : redirectURI.absoluteString,
            "response_type" : "code"
        ]
        let clientId = options?.authServiceId
        set(&json, clientId: clientId)
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.oauthAuth(
                client: client,
                clientId: clientId,
                redirectURI: redirectURI,
                loginPage: false
            ),
            credential: client,
            body: Body.json(json: json),
            options: options
        )
        return request
    }
    
    func buildOAuthGrantAuthenticate(
        redirectURI: URL,
        tempLoginUri: URL,
        username: String,
        password: String,
        options: Options?
    ) -> HttpRequest {
        var params = [
            "response_type" : "code",
            "redirect_uri" : redirectURI.absoluteString,
            "username" : username,
            "password" : password
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.url(url: tempLoginUri),
            credential: client,
            body: Body.formUrlEncoded(params: params),
            options: options
        )
        return request
    }
    
    func buildOAuthGrantRefreshToken(
        refreshToken: String,
        options: Options?
    ) -> HttpRequest {
        var params = [
            "grant_type" : "refresh_token",
            "refresh_token" : refreshToken
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.oauthToken(client: client),
            credential: client,
            body: Body.formUrlEncoded(params: params),
            options: options
        )
        return request
    }
    
    // MARK: Realtime
    
    private func build(
        deviceId: String,
        endpoint: Endpoint,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: endpoint,
            credential: (options?.client ?? self.client).activeUser,
            options: options
        )
        request.setBody(json: [
            "deviceId" : deviceId
        ])
        return request
    }
    
    func buildUserRegisterRealtime(
        user: User,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.userRegisterRealtime(client: options?.client ?? self.client, user: user),
            options: options
        )
    }
    
    func buildUserUnregisterRealtime(
        user: User,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.userUnregisterRealtime(client: options?.client ?? self.client, user: user),
            options: options
        )
    }
    
    func buildAppDataSubscribe(
        collectionName: String,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.appDataSubscribe(client: options?.client ?? self.client, collectionName: collectionName),
            options: options
        )
    }
    
    func buildAppDataUnSubscribe(
        collectionName: String,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.appDataUnSubscribe(client: options?.client ?? self.client, collectionName: collectionName),
            options: options
        )
    }
    
    func buildLiveStreamGrantAccess(
        streamName: String,
        userId: String,
        acl: LiveStreamAcl,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .put,
            endpoint: Endpoint.liveStreamByUser(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            credential: client.activeUser,
            options: options
        )
        request.setBody(json: acl.toJSON())
        return request
    }
    
    func buildLiveStreamAccess(
        streamName: String,
        userId: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .get,
            endpoint: Endpoint.liveStreamByUser(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildLiveStreamPublish(
        streamName: String,
        userId: String,
        options: Options?
    ) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .post,
            endpoint: Endpoint.liveStreamPublish(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildLiveStreamSubscribe(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.liveStreamSubscribe(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            options: options
        )
    }
    
    func buildLiveStreamUnsubscribe(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?
    ) -> HttpRequest {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.liveStreamUnsubscribe(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            options: options
        )
    }

}
