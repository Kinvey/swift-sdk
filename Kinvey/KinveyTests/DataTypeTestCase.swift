//
//  DataTypeTestCase.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import XCTest
import ObjectMapper
@testable import Kinvey

class DataTypeTestCase: StoreTestCase {
    
    func testSave() {
        signUp()
        
        let store = DataStore<DataType>.getInstance(.Network)
        let dataType = DataType()
        dataType.boolValue = true
        dataType.colorValue = UIColor.orangeColor()
        
        let fullName = FullName()
        fullName.firstName = "Victor"
        fullName.lastName = "Barros"
        dataType.fullName = fullName
        
        let fullName2 = FullName2()
        fullName2.firstName = "Victor"
        fullName2.lastName = "Barros"
//        fullName2.fontDescriptor = UIFontDescriptor(name: "Arial", size: 12)
        dataType.fullName2 = fullName2
        
        let tuple = save(dataType, store: store)
        
        XCTAssertNotNil(tuple.savedPersistable)
        if let savedPersistable = tuple.savedPersistable {
            XCTAssertTrue(savedPersistable.boolValue)
        }
        
        let query = Query(format: "_acl.creator == %@", client.activeUser!.userId)
        
        weak var expectationFind = expectationWithDescription("Find")
        
        store.find(query) { results, error in
            XCTAssertNotNil(results)
            XCTAssertNil(error)
            
            if let results = results {
                XCTAssertEqual(results.count, 1)
                
                if let dataType = results.first {
                    XCTAssertTrue(dataType.boolValue)
                    XCTAssertEqual(dataType.colorValue, UIColor.orangeColor())
                    
                    XCTAssertNotNil(dataType.fullName)
                    if let fullName = dataType.fullName {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                    }
                    
                    XCTAssertNotNil(dataType.fullName2)
                    if let fullName = dataType.fullName2 {
                        XCTAssertEqual(fullName.firstName, "Victor")
                        XCTAssertEqual(fullName.lastName, "Barros")
                    }
                }
            }
            
            expectationFind?.fulfill()
        }
        
        waitForExpectationsWithTimeout(defaultTimeout) { (error) in
            expectationFind = nil
        }
    }
    
}

class UIColorTransformType : TransformType {
    
    typealias Object = UIColor
    typealias JSON = JsonDictionary
    
    func transformFromJSON(value: AnyObject?) -> UIColor? {
        if let value = value as? JsonDictionary,
            let red = value["red"] as? CGFloat,
            let green = value["green"] as? CGFloat,
            let blue = value["blue"] as? CGFloat,
            let alpha = value["alpha"] as? CGFloat
        {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        return nil
    }
    
    func transformToJSON(value: UIColor?) -> JsonDictionary? {
        if let value = value {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 9
            value.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return [
                "red" : red,
                "green" : green,
                "blue" : blue,
                "alpha" : alpha
            ]
        }
        return nil
    }
    
}

class DataType: Entity, BooleanType {
    
    dynamic var boolValue: Bool = false
    dynamic var fullName: FullName?
    
    private dynamic var fullName2Value: String?
    dynamic var fullName2: FullName2?
    
    dynamic var objectValue: NSObject?
    
    private dynamic var colorValueString: String?
    dynamic var colorValue: UIColor? {
        get {
            if let colorValueString = colorValueString,
                let data = colorValueString.dataUsingEncoding(NSUTF8StringEncoding),
                let json = try? NSJSONSerialization.JSONObjectWithData(data, options: [])
            {
                return UIColorTransformType().transformFromJSON(json)
            }
            return nil
        }
        set {
            if let newValue = newValue,
                let json = UIColorTransformType().transformToJSON(newValue),
                let data = try? NSJSONSerialization.dataWithJSONObject(json, options: []),
                let stringValue = String(data: data, encoding: NSUTF8StringEncoding)
            {
                colorValueString = stringValue
            } else {
                colorValueString = nil
            }
        }
    }
    
    override class func kinveyCollectionName() -> String {
        return "DataType"
    }
    
    override func mapping(map: Map) {
        super.mapping(map)
        
        boolValue <- map["boolValue"]
        colorValue <- (map["colorValue"], UIColorTransformType())
        fullName <- map["fullName"]
        fullName2 <- (map["fullName2"], FullName2TransformType())
    }
    
    override class func ignoredProperties() -> [String] {
        return ["objectValue", "colorValue", "fullName2"]
    }
    
}

class FullName: Entity {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
    
    override class func kinveyCollectionName() -> String {
        return "FullName"
    }
    
    override func mapping(map: Map) {
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }
    
}

class FullName2TransformType: TransformType {
    
    typealias Object = FullName2
    typealias JSON = JsonDictionary
    
    func transformFromJSON(value: AnyObject?) -> FullName2? {
        return nil
    }
    
    func transformToJSON(value: FullName2?) -> JsonDictionary? {
        return nil
    }
    
}

class FullName2: NSObject, Mappable {
    
    dynamic var firstName: String?
    dynamic var lastName: String?
//    dynamic var fontDescriptor: UIFontDescriptor?
    
    override init() {
    }
    
    required init?(_ map: Map) {
    }
    
    func mapping(map: Map) {
        firstName <- map["firstName"]
        lastName <- map["lastName"]
    }
    
}

//extension UIFontDescriptor: Object {
//    
//    public func toJson() -> JsonDictionary {
//        return [
//            "name" : objectForKey(UIFontDescriptorNameAttribute)!,
//            "size" : objectForKey(UIFontDescriptorSizeAttribute)!
//        ]
//    }
//    
//    public convenience init?(json: JsonDictionary) {
//        self.init(name: json[UIFontDescriptorNameAttribute] as! String, size: json[UIFontDescriptorSizeAttribute] as! CGFloat)
//    }
//    
//}
