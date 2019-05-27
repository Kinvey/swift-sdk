//
//  CustomEndpointParams.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2019-05-17.
//  Copyright © 2019 Kinvey. All rights reserved.
//

import Foundation

extension CustomEndpoint {
    
    /// Parameter Wrapper
    open class Params {
        
        internal let value: JsonDictionary
        
        /**
         Sets the `value` enumeration to a JSON dictionary.
         - parameter json: JSON dictionary to be used as a parameter value
         */
        public init(_ json: JsonDictionary) {
            value = json.toJson()
        }
        
        /**
         Sets the `value` enumeration to any Mappable object or StaticMappable struct.
         - parameter object: Mappable object or StaticMappable struct to be used as a parameter value
         */
        @available(*, deprecated, message: "Deprecated in version 3.18.0. Please use Swift.Codable instead")
        public convenience init<T>(_ object: T) where T: BaseMappable {
            self.init(object.toJSON())
        }
        
        public convenience init(_ object: JSONEncodable) throws {
            self.init(try object.encode())
        }
        
        public convenience init<T>(_ object: T) throws where T: Encodable {
            let data = try jsonEncoder.encode(object)
            let json = try JSONSerialization.jsonObject(with: data) as! JsonDictionary
            self.init(json)
        }
        
    }
    
}
