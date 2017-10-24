//
//  DataValidationStrategy.swift
//  Kinvey
//
//  Created by Victor Hugo Carvalho Barros on 2017-10-12.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import Foundation

/// Defines a strategy to validate results upfront
public enum ValidationStrategy {
    
    /// Percentage between 0.0 and 1.0. This number specifies the fraction of entities in a backend response that are validated. Validating a higher percentage of entities upfront results in a performance penalty.
    case randomSample(percentage: Double)
    
    /// Allow a custom validation strategy. It must return a `Swift.Error` if the validation fails or `nil` if the validation succeed.
    case custom(validationBlock: (Array<Dictionary<String, Any>>) -> Swift.Error?)
    
    func validate(jsonArray: Array<Dictionary<String, Any>>) -> Swift.Error? {
        switch self {
        case .randomSample(let percentage):
            let max = UInt32(jsonArray.count)
            let numberOfItems = min(Int(ceil(Double(jsonArray.count) * percentage)), jsonArray.count)
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
