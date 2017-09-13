//
//  MyFile.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-08-29.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Kinvey

class MyFile: File {
    
    dynamic var label: String?
    
    public convenience required init?(map: Map) {
        self.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        label <- ("label", map["label"])
    }
    
}
