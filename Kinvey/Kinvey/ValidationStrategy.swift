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
    
    /// Validates all items in a backend response. Validating all entities upfront results in a performance penalty.
    case all
    
    /// Percentage between 0.0 and 1.0. This number specifies the fraction of entities in a backend response that are validated. Validating a higher percentage of entities upfront results in a performance penalty.
    case randomSample(percentage: Double)
    
    /// Allow a custom validation strategy. It must return a `Swift.Error` if the validation fails or `nil` if the validation succeed.
    case custom(validationBlock: (Array<Dictionary<String, Any>>) throws -> Void)
    
    func validate(jsonArray: Array<Dictionary<String, Any>>) throws {
        switch self {
        case .all:
            for item in jsonArray {
                try validate(item: item)
            }
        case .randomSample(let percentage):
            let max = UInt32(jsonArray.count)
            let numberOfItems = min(Int(ceil(Double(jsonArray.count) * percentage)), jsonArray.count)
            for _ in 0 ..< numberOfItems {
                let item = jsonArray[Int(arc4random_uniform(max))]
                try validate(item: item)
            }
        case .custom(let validationBlock):
            try validationBlock(jsonArray)
        }
    }
    
    @inline(__always)
    private func validate(item: Dictionary<String, Any>) throws {
        guard
            let id = item[Entity.EntityCodingKeys.entityId] as? String,
            !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            throw Error.objectIdMissing
        }
    }
    
}
