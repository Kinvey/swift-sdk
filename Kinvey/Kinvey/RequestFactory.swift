//
//  NetworkTransport.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-08.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol RequestFactory {
    
    func buildUserSignUp(username username: String?, password: String?) -> Request
    func buildUserDelete(userId userId: String, hard: Bool) -> Request
    func buildUserLogin(username username: String, password: String) -> Request
    func buildUserExists(username username: String) -> Request
    func buildUserGet(userId userId: String) -> Request
    func buildUserSave(user user: User) -> Request
    
    func buildAppDataGetById(collectionName collectionName: String, id: String) -> Request
    func buildAppDataFindByQuery(collectionName collectionName: String, query: Query) -> Request
    func buildAppDataSave<T: Persistable where T: NSObject>(collectionName collectionName: String, persistable: T) -> Request
    func buildAppDataRemoveByQuery(collectionName collectionName: String, query: Query) -> Request
    
    func buildPushRegisterDevice(deviceToken: NSData) -> Request
    func buildPushUnRegisterDevice(deviceToken: NSData) -> Request
    
}
