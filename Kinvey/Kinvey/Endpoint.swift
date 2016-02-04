//
//  Endpoint.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

public enum Endpoint {
    
    case User(client: Client)
    case UserById(client: Client, userId: String)
    case UserExistsByUsername(client: Client)
    case UserLogin(client: Client)
    
    case OAuthAuth(client: Client, redirectURI: NSURL)
    case OAuthToken(client: Client)
    
    case AppData(client: Client, collectionName: String)
    case AppDataById(client: Client, collectionName: String, id: String)
    case AppDataByQuery(client: Client, collectionName: String, query: Query)
    
    case PushRegisterDevice(client: Client)
    case PushUnRegisterDevice(client: Client)
    
    case Blob(client: Client, tls: Bool)
    
    case URL(url: NSURL)
    
}
