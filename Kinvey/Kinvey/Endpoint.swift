//
//  Endpoint.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-01-15.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation

internal enum Endpoint {
    
    case user(client: Client)
    case userById(client: Client, userId: String)
    case userDelete(client: Client, userId: String, hard: Bool)
    case userLookup(client: Client)
    case userExistsByUsername(client: Client)
    case userLogin(client: Client)
    case sendEmailConfirmation(client: Client, username: String)
    case userResetPassword(usernameOrEmail: String, client: Client)
    case userForgotUsername(client: Client)
    
    case appDataPing(client: Client)
    
    case appData(client: Client, collectionName: String)
    case appDataById(client: Client, collectionName: String, id: String)
    case appDataByQuery(client: Client, collectionName: String, query: Query?)
    case appDataCount(client: Client, collectionName: String, query: Query?)
    case appDataGroup(client: Client, collectionName: String)
    
    case pushRegisterDevice(client: Client)
    case pushUnRegisterDevice(client: Client)
    
    case blobById(client: Client, fileId: String)
    case blobUpload(client: Client, fileId: String?, tls: Bool)
    case blobDownload(client: Client, fileId: String?, query: Query?, tls: Bool, ttlInSeconds: UInt?)
    case blobByQuery(client: Client, query: Query)
    
    case url(url: URL)
    case customEndpooint(client: Client, name: String)
    
    case oauthAuth(client: Client, clientId: String?, redirectURI: URL, loginPage: Bool)
    case oauthToken(client: Client)
    
    var url: URL {
        switch self {
        case .user(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)")
        case .userById(let client, let userId):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/\(userId)")
        case .userDelete(let client, let userId, let hard):
            let url = client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/\(userId)")
            if hard {
                return URL(string: url.absoluteString + "?hard=true")!
            }
            return url
        case .userLookup(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/_lookup")
        case .userExistsByUsername(let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/check-username-exists")
        case .userLogin(let client):
            return client.apiHostName.appendingPathComponent("/user/\(client.appKey!)/login")
        case .sendEmailConfirmation(let client, let username):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/\(username)/user-email-verification-initiate")
        case .userResetPassword(let usernameOrEmail, let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/\(usernameOrEmail)/user-password-reset-initiate")
        case .userForgotUsername(let client):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/user-forgot-username")
        case .appDataPing(let client):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)")
        case .appData(let client, let collectionName):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)")
        case .appDataById(let client, let collectionName, let id):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/\(id)")
        case .appDataByQuery(let client, let collectionName, let query):
            let url = client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/").absoluteString
            guard let query = query else {
                return URL(string: url)!
            }
            
            if let urlQueryItems = query.urlQueryItems,
                let url = URL(string: url),
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            {
                urlComponents.queryItems = urlQueryItems
                return urlComponents.url!
            }
            
            return URL(string: url)!
        case .appDataCount(let client, let collectionName, let query):
            let url = client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/_count").absoluteString
            if let query = query {
                if let urlQueryItems = query.urlQueryItems,
                    let url = URL(string: url),
                    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                {
                    urlComponents.queryItems = urlQueryItems
                    return urlComponents.url!
                }
            }
            return URL(string: url)!
        case .appDataGroup(let client, let collectionName):
            return client.apiHostName.appendingPathComponent("/appdata/\(client.appKey!)/\(collectionName)/_group")
        case .pushRegisterDevice(let client):
            return client.apiHostName.appendingPathComponent("/push/\(client.appKey!)/register-device")
        case .pushUnRegisterDevice(let client):
            return client.apiHostName.appendingPathComponent("/push/\(client.appKey!)/unregister-device")
        case .blobById(let client, let fileId):
            return Endpoint.blobDownload(client: client, fileId: fileId, query: nil, tls: false, ttlInSeconds: nil).url
        case .blobUpload(let client, let fileId, let tls):
            return Endpoint.blobDownload(client: client, fileId: fileId, query: nil, tls: tls, ttlInSeconds: nil).url
        case .blobDownload(let client, let fileId, let query, let tls, let ttlInSeconds):
            let url = client.apiHostName.appendingPathComponent("/blob/\(client.appKey!)/\(fileId ?? "")").absoluteString
            
            var urlQueryItems = [URLQueryItem]()
            
            if tls {
                let tls = URLQueryItem(name: "tls", value: "true")
                urlQueryItems.append(tls)
            }
            
            if let ttlInSeconds = ttlInSeconds {
                let ttl = URLQueryItem(name: "ttl_in_seconds", value: String(ttlInSeconds))
                urlQueryItems.append(ttl)
            }
            
            if let query = query,
                let queryURLQueryItems = query.urlQueryItems
            {
                urlQueryItems.append(contentsOf: queryURLQueryItems)
            }
            
            if urlQueryItems.count > 0,
                let url = URL(string: url),
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            {
                urlComponents.queryItems = urlQueryItems
                return urlComponents.url!
            }
            return URL(string: url)!
        case .blobByQuery(let client, let query):
            return Endpoint.blobDownload(client: client, fileId: nil, query: query, tls: true, ttlInSeconds: nil).url
        case .url(let url):
            return url
        case .customEndpooint(let client, let name):
            return client.apiHostName.appendingPathComponent("/rpc/\(client.appKey!)/custom/\(name)")
        case .oauthAuth(let client, let clientId, let redirectURI, let loginPage):
            var url = client.authHostName
            if let micApiVersion = client.micApiVersion {
                url.appendPathComponent(micApiVersion.rawValue)
            }
            url.appendPathComponent("/oauth/auth")
            if loginPage {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
                var queryItems = [URLQueryItem]()
                if let appKey = client.appKey {
                    if let clientId = clientId {
                        queryItems.append(URLQueryItem(name: "client_id", value: "\(appKey):\(clientId)"))
                    } else {
                        queryItems.append(URLQueryItem(name: "client_id", value: appKey))
                    }
                }
                queryItems.append(URLQueryItem(name: "redirect_uri", value: redirectURI.absoluteString))
                queryItems.append(URLQueryItem(name: "response_type", value: "code"))
                if let micApiVersion = client.micApiVersion, micApiVersion == .v3 {
                    queryItems.append(URLQueryItem(name: "scope", value: "openid"))
                }
                components.queryItems = queryItems
                url = components.url!
            }
            return url
        case .oauthToken(let client):
            var url = client.authHostName
            if let micApiVersion = client.micApiVersion {
                url.appendPathComponent(micApiVersion.rawValue)
            }
            url.appendPathComponent("/oauth/token")
            return url
        }
    }
    
}
