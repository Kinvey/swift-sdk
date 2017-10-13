//
//  DataValidationStrategy.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2017-10-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

public enum ValidationStrategy {
    
    case randomNumberOfItems(numberOfItems: UInt32)
    case custom(validationBlock: (Array<Dictionary<String, Any>>) -> Swift.Error?)
    
    func validate(jsonArray: Array<Dictionary<String, Any>>) -> Swift.Error? {
        switch self {
        case .randomNumberOfItems(let numberOfItems):
            let max = UInt32(jsonArray.count)
            for _ in 0 ..< numberOfItems {
                let item = jsonArray[Int(arc4random_uniform(max))]
                guard
                    let id = item[Entity.Key.entityId] as? String,
                    !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else {
                    return Error.objectIdMissing
                }
            }
            return nil
        case .custom(let validationBlock):
            return validationBlock(jsonArray)
        }
    }
    
}
