//
//  Book.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-07-11.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

class Book: Entity {
    
    @objc
    dynamic var title: String?
    
    let authorNames = List<StringValue>()
    
    let editions = List<BookEdition>()
    
    @objc
    dynamic var nextEdition: BookEdition?
    
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
        authorNames <- ("authorNames", map["author_names"])
        
        editions <- ("editions", map["editions"])
        nextEdition <- ("nextEdition", map["next_edition"])
        
        editionsYear <- ("editionsYear", map["editions_year"])
        editionsRetailPrice <- ("editionsRetailPrice", map["editions_retail_price"])
        editionsRating <- ("editionsRating", map["editions_rating"])
        editionsAvailable <- ("editionsAvailable", map["editions_available"])
    }
    
}

extension Book {
    
    convenience init(_ block: (Book) -> Void) {
        self.init()
        block(self)
    }
    
}

class BookEdition: Object, JSONDecodable, Mappable {
    
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
        retailPrice <- ("retailPrice", map["retail_price"])
        rating <- ("rating", map["rating"])
        available <- ("available", map["available"])
    }
    
    static func decode<T>(from dictionary: [String : Any]) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: dictionary)
    }
    
    static func decode<T>(from data: Data) throws -> T where T : JSONDecodable {
        return try decodeJSONDecodable(from: data)
    }
    
    static func decodeArray<T>(from data: Data) throws -> [T] where T : JSONDecodable {
        return try decodeArrayJSONDecodable(from: data)
    }
    
    func refresh(from dictionary: [String : Any]) throws {
        var _self = self
        try _self.refreshJSONDecodable(from: dictionary)
    }
    
}
