//
//  RealmResultsArray.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-06-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import Foundation
import RealmSwift

class RealmResultsArray<T: Object>: NSArray {
    
    let results: Results<T>
    
    init(_ results: Results<T>) {
        self.results = results
        super.init()
    }
    
    override var count: Int {
        return results.count
    }
    
    override func objectAtIndex(index: Int) -> AnyObject {
        return results[index]
    }
    
}
