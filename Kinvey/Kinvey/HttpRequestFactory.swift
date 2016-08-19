//
//  HttpNetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

class HttpRequestFactory: RequestFactory {
    
    let client: Client
    
    required init(client: Client) {
        self.client = client
    }
    
    typealias CompletionHandler = (NSData?, NSURLResponse?, NSError?) -> Void
    
    func buildUserSignUp(username username: String? = nil, password: String? = nil) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.User(client: client), client: client)
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var bodyObject = JsonDictionary()
        if let username = username {
            bodyObject["username"] = username
        }
        if let password = password {
            bodyObject["password"] = password
        }
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserDelete(userId userId: String, hard: Bool) -> HttpRequest {
        
        
        let request = HttpRequest(httpMethod: .Delete, endpoint: Endpoint.UserDelete(client: client, userId: userId, hard: hard), credential: client.activeUser, client: client)

        //FIXME: make it configurable
        request.request.setValue("2", forHTTPHeaderField: "X-Kinvey-API-Version")
        return request
    }
    
    func buildUserSocialLogin(authSource: String, authData: [String : AnyObject]) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.User(client: client), client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let socialIdentity = [
            authSource : authData
        ]
        let bodyObject = [
            "_socialIdentity" : socialIdentity
        ]
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserLogin(username username: String, password: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.UserLogin(client: client), client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = [
            "username" : username,
            "password" : password
        ]
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserExists(username username: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.UserExistsByUsername(client: client), client: client)
        request.request.HTTPMethod = "POST"
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = ["username" : username]
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserGet(userId userId: String) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.UserById(client: client, userId: userId), credential: client.activeUser, client: client)
        return request
    }
    
    func buildUserSave(user user: User) -> HttpRequest {
        return buildUserSave(user: user, newPassword: nil)
    }
    
    func buildUserSave(user user: User, newPassword: String?) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Put, endpoint: Endpoint.UserById(client: client, userId: user.userId), credential: client.activeUser, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var bodyObject = user.toJSON()
        
        if let newPassword = newPassword {
            bodyObject["password"] = newPassword
        }
        
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserLookup(user user: User, userQuery: UserQuery) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.UserLookup(client: client), credential: client.activeUser, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = userQuery.toJSON()
        
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildUserResetPassword(usernameOrEmail usernameOrEmail: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.UserResetPassword(usernameOrEmail: usernameOrEmail, client: client), credential: client, client: client)
        return request
    }
    
    func buildUserForgotUsername(email email: String) -> HttpRequest {
        let request = HttpRequest(httpMethod: .Post, endpoint: Endpoint.UserForgotUsername(client: client), credential: client, client: client)
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let bodyObject = ["email" : email]
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildAppDataGetById(collectionName collectionName: String, id: String) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.AppDataById(client: client, collectionName: collectionName, id: id), credential: client.activeUser, client: client)
        return request
    }
    
    func buildAppDataFindByQuery(collectionName collectionName: String, query: Query) -> HttpRequest {
        let request = HttpRequest(endpoint: Endpoint.AppDataByQuery(client: client, collectionName: collectionName, query: query), credential: client.activeUser, client: client)
        return request
    }
    
    func buildAppDataSave<T: Persistable>(persistable: T) -> HttpRequest {
        let collectionName = T.collectionName()
        let bodyObject = Mapper<T>().toJSON(persistable)
        let objId = bodyObject[PersistableIdKey] as? String
        let isNewObj = objId == nil
        let request = HttpRequest(
            httpMethod: isNewObj ? .Post : .Put,
            endpoint: isNewObj ? Endpoint.AppData(client: client, collectionName: collectionName) : Endpoint.AppDataById(client: client, collectionName: collectionName, id: objId!),
            credential: client.activeUser,
            client: client
        )
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildAppDataRemoveByQuery(collectionName collectionName: String, query: Query) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Delete,
            endpoint: Endpoint.AppDataByQuery(client: client, collectionName: collectionName, query: query),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildAppDataRemoveById(collectionName collectionName: String, objectId: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Delete,
            endpoint: Endpoint.AppDataById(client: client, collectionName: collectionName, id: objectId),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildPushRegisterDevice(deviceToken: NSData) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Post,
            endpoint: Endpoint.PushRegisterDevice(client: client),
            credential: client.activeUser,
            client: client
        )
        
        let bodyObject = [
            "platform" : "ios",
            "deviceId" : deviceToken.hexString()
        ]
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildPushUnRegisterDevice(deviceToken: NSData) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Post,
            endpoint: Endpoint.PushUnRegisterDevice(client: client),
            credential: client.activeUser,
            client: client
        )
        
        let bodyObject = [
            "platform" : "ios",
            "deviceId" : deviceToken.hexString()
        ]
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    func buildBlobUploadFile(file: File) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: file.fileId == nil ? .Post : .Put,
            endpoint: Endpoint.BlobUpload(client: client, fileId: file.fileId, tls: true),
            credential: client.activeUser,
            client: client
        )
        
        var bodyObject: [String : AnyObject] = [
            "_public" : file.publicAccessible
        ]
        
        if let fileId = file.fileId {
            bodyObject["_id"] = fileId
        }
        
        if let fileName = file.fileName {
            bodyObject["_filename"] = fileName
        }
        
        if let size = file.size.value {
            bodyObject["size"] = String(size)
        }
        
        if let mimeType = file.mimeType {
            bodyObject["mimeType"] = mimeType
        }
        
        request.request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.request.setValue(file.mimeType ?? "application/octet-stream", forHTTPHeaderField: "X-Kinvey-Content-Type")
        request.request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(bodyObject, options: [])
        return request
    }
    
    private func ttlInSeconds(ttl: TTL?) -> UInt? {
        if let ttl = ttl {
            return UInt(ttl.1.toTimeInterval(ttl.0))
        }
        return nil
    }
    
    func buildBlobDownloadFile(file: File, ttl: TTL?) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Get,
            endpoint: Endpoint.BlobDownload(client: client, fileId: file.fileId!, query: nil, tls: true, ttlInSeconds: ttlInSeconds(ttl)),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildBlobDeleteFile(file: File) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Delete,
            endpoint: Endpoint.BlobById(client: client, fileId: file.fileId!),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildBlobQueryFile(query: Query, ttl: TTL?) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Get,
            endpoint: Endpoint.BlobDownload(client: client, fileId: nil, query: query, tls: true, ttlInSeconds: ttlInSeconds(ttl)),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildCustomEndpoint(name: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Post,
            endpoint: Endpoint.CustomEndpooint(client: client, name: name),
            credential: client.activeUser,
            client: client
        )
        return request
    }
    
    func buildSendEmailConfirmation(forUsername username: String) -> HttpRequest {
        let request = HttpRequest(
            httpMethod: .Post,
            endpoint: Endpoint.SendEmailConfirmation(client: client, username: username),
            credential: client,
            client: client
        )
        return request
    }

}
