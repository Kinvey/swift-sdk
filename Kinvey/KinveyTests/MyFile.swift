//
//  MyFile.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-08-29.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation
import Kinvey

@objc protocol MyFileProtocol {
    @objc
    dynamic var label: String? { get set }
}

class MyFile: File, MyFileProtocol {

    enum MyCodingKeys: String, CodingKey {
        case label
    }

    var label: String?

    override func mapping(map: Map) {
        super.mapping(map: map)

        label <- ("label", map["label"])
    }

}

class MyFileCodable : File, MyFileProtocol, Codable {
    var label: String?
    
    enum MyCodingKeys: String, CodingKey {
        case label
    }

    public required override init() {
        super.init()
    }

    public required override init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: MyCodingKeys.self)
        label = try container.decodeIfPresent(String.self, forKey: .label)
        try super.init(from: decoder)
    }

    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: MyCodingKeys.self)
        try container.encodeIfPresent(label, forKey: .label)
    }
}
