//
//  Book.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Kinvey

class Book: Entity {
    
    @objc
    dynamic var title: String?
    
    let authorNames = List<StringValue>()
    
    let editions = List<BookEdition>()
    
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
        
        editions <- ("editions", map["editions"])
        
        editionsYear <- ("editionsYear", map["editionsYear"])
        editionsRetailPrice <- ("editionsRetailPrice", map["editionsRetailPrice"])
        editionsRating <- ("editionsRating", map["editionsRating"])
        editionsAvailable <- ("editionsAvailable", map["editionsAvailable"])
    }
    
}

class BookEdition: Object, Mappable {
    
    convenience required init?(map: Map) {
        self.init()
    }
    
    @objc
    dynamic var year: Int = 0
    
    @objc
    dynamic var retailPrice: Float = 0.0
    
    @objc
    dynamic var rating: Float = 0.0
    
    @objc
    dynamic var available: Bool = false
    
    func mapping(map: Map) {
        year <- ("year", map["year"])
        retailPrice <- ("retailPrice", map["retailPrice"])
        rating <- ("rating", map["rating"])
        available <- ("available", map["available"])
    }
    
}
