//
//  JsonObject.swift
//  Kinvey
//
//  Created by Victor Barros on 2015-12-09.
//  Copyright © 2015 Kinvey. All rights reserved.
//

import UIKit

protocol JsonObject {
    
    func toJson() -> [String : AnyObject]

}
