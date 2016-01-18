//
//  Credentials.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-14.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import Foundation

public protocol Credential {
    
    var authorizationHeader: String? { get }

}
