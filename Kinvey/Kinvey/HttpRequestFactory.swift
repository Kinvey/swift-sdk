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
    
    func buildUserSignUp<Result>(
        username: String? = nil,
        password: String? = nil,
        user: User? = nil,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    
    func buildUserDelete<Result>(
        userId: String,
        hard: Bool,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    ) -> HttpRequest<Any> {
        let bodyObject = [
            "_socialIdentity" : [
                authSource.rawValue : authData
            ]
        ]
        let request = HttpRequest<Any>(
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
    ) -> HttpRequest<Any> {
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
    ) -> HttpRequest<Any> {
        return buildUserSocial(
            authSource,
            authData: authData,
            endpoint: Endpoint.user(client: client, query: nil),
            options: options
        )
    }
    
    func buildUserLogin<Result>(
        username: String,
        password: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    
    func buildUserLogout<Result>(
        user: User,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.userLogout(client: client),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserExists<Result>(
        username: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.userExistsByUsername(client: client),
            options: options
        )
        request.request.httpMethod = "POST"
        
        let bodyObject = ["username" : username]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserGet<Result>(
        userId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            endpoint: Endpoint.userById(client: client, userId: userId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserFind<Result>(
        query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            endpoint: Endpoint.user(client: client, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildUserSave<Result>(
        user: User,
        newPassword: String?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    
    func buildUserLookup<Result>(
        user: User,
        userQuery: UserQuery,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.userLookup(client: client),
            credential: client.activeUser,
            options: options
        )
        let bodyObject = userQuery.toJSON()
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserResetPassword<Result>(
        usernameOrEmail: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.userResetPassword(usernameOrEmail: usernameOrEmail, client: client),
            credential: client,
            options: options
        )
        return request
    }
    
    func buildUserForgotUsername<Result>(
        email: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.userForgotUsername(client: client),
            credential: client,
            options: options
        )
        let bodyObject = ["email" : email]
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildUserMe<Result>(
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            endpoint: Endpoint.userMe(client: client),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataPing<Result>(
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .get,
            endpoint: Endpoint.appDataPing(client: client),
            options: options
        )
        return request
    }
    
    func buildAppDataGetById<Result>(
        collectionName: String,
        id: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    ) -> HttpRequest<Any> {
        let request = HttpRequest<Any>(
            endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query.isEmpty ? nil : query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataCountByQuery<Result>(
        collectionName: String,
        query: Query?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            endpoint: Endpoint.appDataCount(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataGroup<Result>(
        collectionName: String,
        keys: [String],
        initialObject: [String : Any],
        reduceJSFunction: String,
        condition: NSPredicate?,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    
    func buildAppDataSave<T: Persistable, Result>(
        _ persistable: T,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let collectionName = T.collectionName()
        var bodyObject = persistable.toJSON()
        let objId = bodyObject[Entity.Key.entityId] as? String
        let isNewObj = objId == nil || objId!.hasPrefix(ObjectIdTmpPrefix)
        let request = HttpRequest<Result>(
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
    
    func buildAppDataRemoveByQuery<Result>(
        collectionName: String,
        query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let query = Query(query)
        query.emptyPredicateMustReturnNil = false
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: Endpoint.appDataByQuery(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataRemoveById<Result>(
        collectionName: String,
        objectId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    ) -> HttpRequest<Any> {
        let request = HttpRequest<Any>(
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
    
    func buildPushRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        return buildPushDevice(
            deviceToken,
            options: options,
            client: client,
            endpoint: Endpoint.pushRegisterDevice(client: client)
        )
    }
    
    func buildPushUnRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest<Any> {
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
    ) -> HttpRequest<Any> {
        let request = HttpRequest<Any>(
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
    
    func buildBlobDownloadFile<Result>(
        _ file: File,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let ttl = options?.ttl
        let request = HttpRequest<Result>(
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
    
    func buildBlobDeleteFile<Result>(
        _ file: File,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: Endpoint.blobById(client: client, fileId: file.fileId!),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildBlobQueryFile<Result>(
        _ query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let ttl = options?.ttl
        let request = HttpRequest<Result>(
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
    
    func buildCustomEndpoint<Result>(
        _ name: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: Endpoint.customEndpooint(client: client, name: name),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildSendEmailConfirmation<Result>(
        forUsername username: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    ) -> HttpRequest<Any> {
        var params = [
            "grant_type" : "authorization_code",
            "redirect_uri" : redirectURI.absoluteString,
            "code" : code
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest<Any>(
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
    ) -> HttpRequest<Any> {
        var json = [
            "redirect_uri" : redirectURI.absoluteString,
            "response_type" : "code"
        ]
        let clientId = options?.authServiceId
        set(&json, clientId: clientId)
        let request = HttpRequest<Any>(
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
    ) -> HttpRequest<Any> {
        var params = [
            "response_type" : "code",
            "redirect_uri" : redirectURI.absoluteString,
            "username" : username,
            "password" : password
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest<Any>(
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
    ) -> HttpRequest<Any> {
        var params = [
            "grant_type" : "refresh_token",
            "refresh_token" : refreshToken
        ]
        set(&params, clientId: options?.authServiceId)
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: Endpoint.oauthToken(client: client),
            credential: client,
            body: Body.formUrlEncoded(params: params),
            options: options
        )
        return request
    }
    
    // MARK: Realtime
    
    private func build<Result>(
        deviceId: String,
        endpoint: Endpoint,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    
    func buildUserRegisterRealtime<Result>(
        user: User,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.userRegisterRealtime(client: options?.client ?? self.client, user: user),
            options: options,
            resultType: resultType
        )
    }
    
    func buildUserUnregisterRealtime<Result>(
        user: User,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.userUnregisterRealtime(client: options?.client ?? self.client, user: user),
            options: options,
            resultType: resultType
        )
    }
    
    func buildAppDataSubscribe<Result>(
        collectionName: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.appDataSubscribe(client: options?.client ?? self.client, collectionName: collectionName),
            options: options,
            resultType: resultType
        )
    }
    
    func buildAppDataUnSubscribe<Result>(
        collectionName: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.appDataUnSubscribe(client: options?.client ?? self.client, collectionName: collectionName),
            options: options,
            resultType: resultType
        )
    }
    
    func buildLiveStreamGrantAccess<Result>(
        streamName: String,
        userId: String,
        acl: LiveStreamAcl,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .put,
            endpoint: Endpoint.liveStreamByUser(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            credential: client.activeUser,
            options: options
        )
        request.setBody(json: acl.toJSON())
        return request
    }
    
    func buildLiveStreamAccess<Result>(
        streamName: String,
        userId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
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
    ) -> HttpRequest<Any> {
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: Endpoint.liveStreamPublish(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildLiveStreamSubscribe<Result>(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.liveStreamSubscribe(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            options: options,
            resultType: resultType
        )
    }
    
    func buildLiveStreamUnsubscribe<Result>(
        streamName: String,
        userId: String,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        return build(
            deviceId: deviceId,
            endpoint: Endpoint.liveStreamUnsubscribe(client: options?.client ?? self.client, streamName: streamName, userId: userId),
            options: options,
            resultType: resultType
        )
    }

}
