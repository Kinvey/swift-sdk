//
//  HttpNetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

struct HttpRequestFactory: RequestFactory {
    
    let client: Client
    
    let user: UserRequestFactory
    
    let appData: AppDataRequestFactory
    
    let push: PushRequestFactory
    
    let blob: BlobRequestFactory
    
    let stream: StreamRequestFactory
    
    let oauth: OAuthRequestFactory
    
    func buildCustomEndpoint<Result>(
        _ name: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: RpcEndpoint.customEndpooint(client: client, name: name),
            credential: client.activeUser,
            options: options
        )
        return request
    }

}

extension HttpRequestFactory {
    
    init(client: Client) {
        self.client = client
        self.user = HttpUserRequestFactory(client: client)
        self.appData = HttpAppDataRequestFactory(client: client)
        self.push = HttpPushRequestFactory(client: client)
        self.blob = HttpBlobRequestFactory(client: client)
        self.stream = HttpStreamRequestFactory(client: client)
        self.oauth = HttpOAuthRequestFactory(client: client)
    }
    
}

struct HttpUserRequestFactory: UserRequestFactory {
    
    let client: Client
    
    func buildUserSignUp<Result>(
        username: String? = nil,
        password: String? = nil,
        user: User? = nil,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: UserEndpoint.user(client: client, query: nil),
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
            bodyObject += try! client.jsonParser.toJSON(user)
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: UserEndpoint.userDelete(client: client, userId: userId, hard: hard),
            credential: client.activeUser,
            options: options
        )

        request.request.setValue("\(restApiVersion)", forHTTPHeaderField: "X-Kinvey-API-Version")
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
        let client = options?.client ?? self.client
        return buildUserSocial(
            authSource,
            authData: authData,
            endpoint: UserEndpoint.userLogin(client: client),
            options: options
        )
    }
    
    func buildUserSocialCreate(
        _ authSource: AuthSource,
        authData: [String : Any],
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        return buildUserSocial(
            authSource,
            authData: authData,
            endpoint: UserEndpoint.user(client: client, query: nil),
            options: options
        )
    }
    
    func buildUserLogin<Result>(
        username: String,
        password: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: UserEndpoint.userLogin(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: UserEndpoint.userLogout(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: RpcEndpoint.userExistsByUsername(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            endpoint: UserEndpoint.userById(client: client, userId: userId),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            endpoint: UserEndpoint.user(client: client, query: query),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .put,
            endpoint: UserEndpoint.userById(client: client, userId: user.userId),
            credential: client.activeUser,
            options: options
        )
        var bodyObject = try! client.jsonParser.toJSON(user)
        
        if let newPassword = newPassword {
            bodyObject["password"] = newPassword
        }
        
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildSendEmailConfirmation<Result>(
        forUsername username: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: RpcEndpoint.sendEmailConfirmation(client: client, username: username),
            credential: client,
            options: options
        )
        return request
    }
    
    func buildUserLookup<Result>(
        user: User,
        userQuery: UserQuery,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: UserEndpoint.userLookup(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: RpcEndpoint.userResetPassword(usernameOrEmail: usernameOrEmail, client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: RpcEndpoint.userForgotUsername(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            endpoint: UserEndpoint.userMe(client: client),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
}

struct HttpAppDataRequestFactory: AppDataRequestFactory {
    
    let client: Client
    
    func buildAppDataPing<Result>(
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .get,
            endpoint: AppDataEndpoint.appDataPing(client: client),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            endpoint: AppDataEndpoint.appDataById(client: client, collectionName: collectionName, id: id),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Any>(
            endpoint: AppDataEndpoint.appDataByQuery(client: client, collectionName: collectionName, query: query.isEmpty ? nil : query),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
    func buildAppDataFindByQueryDeltaSet(
        collectionName: String,
        query: Query,
        sinceDate: Date,
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Any>(
            endpoint: AppDataEndpoint.appDataByQueryDeltaSet(client: client, collectionName: collectionName, query: query.isEmpty ? nil : query, sinceDate: sinceDate),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            endpoint: AppDataEndpoint.appDataCount(client: client, collectionName: collectionName, query: query),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: AppDataEndpoint.appDataGroup(client: client, collectionName: collectionName),
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
        isNew: Bool?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let collectionName = try! T.collectionName()
        let client = options?.client ?? self.client
        var bodyObject = try! client.jsonParser.toJSON(persistable)
        let objId = bodyObject[Entity.EntityCodingKeys.entityId] as? String
        let isNewObj = isNew ?? Kinvey.isNew(entityId: objId)
        let request = HttpRequest<Result>(
            httpMethod: isNewObj ? .post : .put,
            endpoint: isNewObj ? AppDataEndpoint.appData(client: client, collectionName: collectionName) : AppDataEndpoint.appDataById(client: client, collectionName: collectionName, id: objId!),
            credential: client.activeUser,
            options: options
        )
        
        if isNewObj {
            bodyObject[Entity.EntityCodingKeys.entityId] = nil
        }
        
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildAppDataSave<S: Sequence, T: Persistable, Result>(
        _ persistable: S,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> where S.Element == T {
        let collectionName = try! T.collectionName()
        let client = options?.client ?? self.client
        let bodyObject = try! client.jsonParser.toJSON(persistable).map { (json) -> JsonDictionary in
            var json = json
            if isNew(entityId: json[Entity.EntityCodingKeys.entityId.rawValue] as? String) {
                json.removeValue(forKey: Entity.EntityCodingKeys.entityId.rawValue)
            }
            return json
        }
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: AppDataEndpoint.appData(client: client, collectionName: collectionName),
            credential: client.activeUser,
            options: options
        )
        
        request.setBody(json: bodyObject)
        return request
    }
    
    func buildAppDataRemoveByQuery<Result>(
        collectionName: String,
        query: Query,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let query = Query(query)
        query.emptyPredicateMustReturnNil = false
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: AppDataEndpoint.appDataByQuery(client: client, collectionName: collectionName, query: query),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: AppDataEndpoint.appDataById(client: client, collectionName: collectionName, id: objectId),
            credential: client.activeUser,
            options: options
        )
        return request
    }
    
}

struct HttpPushRequestFactory: PushRequestFactory {
    
    let client: Client
    
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
            endpoint: PushEndpoint.pushRegisterDevice(client: client)
        )
    }
    
    func buildPushUnRegisterDevice(_ deviceToken: Data, options: Options?) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        return buildPushDevice(
            deviceToken,
            options: options,
            client: client,
            endpoint: PushEndpoint.pushUnRegisterDevice(client: client)
        )
    }
    
}

struct HttpBlobRequestFactory: BlobRequestFactory {
    
    let client: Client
    
    func buildBlobUploadFile(
        _ file: File,
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Any>(
            httpMethod: file.fileId == nil ? .post : .put,
            endpoint: BlobEndpoint.blobUpload(
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
    
    func buildBlobDownloadFile<Result>(
        _ file: File,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let ttl = options?.ttl
        let request = HttpRequest<Result>(
            httpMethod: .get,
            endpoint: BlobEndpoint.blobDownload(
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .delete,
            endpoint: BlobEndpoint.blobById(client: client, fileId: file.fileId!),
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
        let client = options?.client ?? self.client
        let ttl = options?.ttl
        let request = HttpRequest<Result>(
            httpMethod: .get,
            endpoint: BlobEndpoint.blobDownload(
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
    
    private func ttlInSeconds(_ ttl: TTL?) -> UInt? {
        guard let (value, unit) = ttl else {
            return nil
        }
        return UInt(unit.toTimeInterval(value))
    }
    
}

struct HttpOAuthRequestFactory: OAuthRequestFactory {
    
    let client: Client
    
    private func buildOAuth(
        params: [String : String],
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        let credential: Credential
        if let authServiceId = options?.authServiceId,
            let appKey = client.appKey,
            let appSecret = client.appSecret
        {
            credential = BasicAuthCredential(
                username: "\(appKey).\(authServiceId)",
                password: appSecret
            )
        } else {
            credential = client
        }
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: OAuthEndpoint.oauthToken(client: client),
            credential: credential,
            body: Body.formUrlEncoded(params: params),
            options: options
        )
        return request
    }
    
    func buildOAuthToken(
        redirectURI: URL,
        code: String,
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        var params = [
            "grant_type" : "authorization_code",
            "redirect_uri" : redirectURI.absoluteString,
            "code" : code
        ]
        set(&params, clientId: options?.authServiceId, client: client)
        return buildOAuth(params: params, options: options)
    }
    
    func buildOAuthToken(
        username: String,
        password: String,
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        var params = [
            "grant_type" : "password",
            "username" : username,
            "password" : password
        ]
        set(&params, clientId: options?.authServiceId, client: client)
        return buildOAuth(params: params, options: options)
    }
    
    func buildOAuthGrantAuth(
        redirectURI: URL,
        options: Options?
    ) -> HttpRequest<Any> {
        let client = options?.client ?? self.client
        var json = [
            "redirect_uri" : redirectURI.absoluteString,
            "response_type" : "code"
        ]
        let clientId = options?.authServiceId
        set(&json, clientId: clientId, client: client)
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: OAuthEndpoint.oauthAuth(
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
        let client = options?.client ?? self.client
        var params = [
            "response_type" : "code",
            "redirect_uri" : redirectURI.absoluteString,
            "username" : username,
            "password" : password
        ]
        set(&params, clientId: options?.authServiceId, client: client)
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: URLEndpoint(url: tempLoginUri),
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
        set(&params, clientId: options?.authServiceId, client: options?.client ?? self.client)
        return buildOAuth(params: params, options: options)
    }
    
    private func set(_ params: inout [String : String], clientId: String?, client: Client) {
        if let appKey = client.appKey {
            if let clientId = clientId {
                params["client_id"] = "\(appKey).\(clientId)"
            } else {
                params["client_id"] = appKey
            }
        }
    }
    
}

struct HttpStreamRequestFactory: StreamRequestFactory {
    
    let client: Client
    
    func buildLiveStreamAccess<Result>(
        streamName: String,
        userId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .get,
            endpoint: StreamEndpoint.liveStreamByUser(client: client, streamName: streamName, userId: userId),
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
        let client = options?.client ?? self.client
        let request = HttpRequest<Any>(
            httpMethod: .post,
            endpoint: StreamEndpoint.liveStreamPublish(client: client, streamName: streamName, userId: userId),
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
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: StreamEndpoint.liveStreamSubscribe(client: client, streamName: streamName, userId: userId),
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
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: StreamEndpoint.liveStreamUnsubscribe(client: client, streamName: streamName, userId: userId),
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
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: AppDataEndpoint.appDataSubscribe(client: client, collectionName: collectionName),
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
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: AppDataEndpoint.appDataUnSubscribe(client: client, collectionName: collectionName),
            options: options,
            resultType: resultType
        )
    }
    
    func buildUserRegisterRealtime<Result>(
        user: User,
        deviceId: String,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: UserEndpoint.userRegisterRealtime(client: client, user: user),
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
        let client = options?.client ?? self.client
        return buildRequest(
            deviceId: deviceId,
            endpoint: UserEndpoint.userUnregisterRealtime(client: client, user: user),
            options: options,
            resultType: resultType
        )
    }
    
    private func buildRequest<Result>(
        deviceId: String,
        endpoint: Endpoint,
        options: Options?,
        resultType: Result.Type
    ) -> HttpRequest<Result> {
        let client = options?.client ?? self.client
        let request = HttpRequest<Result>(
            httpMethod: .post,
            endpoint: endpoint,
            credential: client.activeUser,
            options: options
        )
        request.setBody(json: [
            "deviceId" : deviceId
        ])
        return request
    }
    
}
