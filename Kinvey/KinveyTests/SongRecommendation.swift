//
//  SongRecommendation.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-06-08.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import ObjectMapper

struct SongRecommendation: StaticMappable {
    
    var name: String?
    var artist: String?
    var rating: Int?
    
    static func objectForMapping(map: Map) -> BaseMappable? {
        return SongRecommendation()
    }
    
    mutating func mapping(map: Map) {
        name <- map["song_name"]
        artist <- map["song_artist"]
        rating <- map["rating"]
    }
    
}

class SongRecommendationClass: Mappable {
    
    var name: String?
    var artist: String?
    var rating: Int?
    
    required init?(map: Map) {
    }
    
    init(name: String? = nil, artist: String? = nil, rating: Int? = nil) {
        self.name = name
        self.artist = artist
        self.rating = rating
    }
    
    func mapping(map: Map) {
        name <- map["song_name"]
        artist <- map["song_artist"]
        rating <- map["rating"]
    }
    
}
