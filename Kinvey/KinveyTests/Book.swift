//
//  Book.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class Book: Entity {
    
    dynamic var title: String?
    let authorNames = List<StringValue>()
    let editionsYear = List<IntValue>()
    let editionsRetailPrice = List<FloatValue>()
    let editionsRating = List<DoubleValue>()
    let editionsAvailable = List<BoolValue>()
    
    override class func collectionName() -> String {
        return "Book"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        title <- ("title", map["title"])
        authorNames <- ("authorNames", map["authorNames"])
        editionsYear <- ("editionsYear", map["editionsYear"])
        editionsRetailPrice <- ("editionsRetailPrice", map["editionsRetailPrice"])
        editionsRating <- ("editionsRating", map["editionsRating"])
        editionsAvailable <- ("editionsAvailable", map["editionsAvailable"])
    }
    
}
