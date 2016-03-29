//
//  Endpoint.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal enum Endpoint {
    
    case User(client: Client)
    case UserById(client: Client, userId: String)
    case UserExistsByUsername(client: Client)
    case UserLogin(client: Client)
    case UserResetPassword(usernameOrEmail: String, client: Client)
    case UserForgotUsername(client: Client)
    
    case OAuthAuth(client: Client, redirectURI: NSURL)
    case OAuthToken(client: Client)
    
    case AppData(client: Client, collectionName: String)
    case AppDataById(client: Client, collectionName: String, id: String)
    case AppDataByQuery(client: Client, collectionName: String, query: Query, fields: Set<String>?)
    
    case PushRegisterDevice(client: Client)
    case PushUnRegisterDevice(client: Client)
    
    case BlobById(client: Client, fileId: String)
    case BlobUpload(client: Client, fileId: String?, tls: Bool)
    case BlobDownload(client: Client, fileId: String?, query: Query?, tls: Bool, ttlInSeconds: UInt?)
    case BlobByQuery(client: Client, query: Query)
    
    case URL(url: NSURL)
    
}
