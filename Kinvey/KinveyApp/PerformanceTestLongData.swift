//
//  PeformanceTestLongData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class PerformanceTestLongData: PerformanceTestData {
    
    override func test() {
        startDate = Date()
        let store: DataStore<LongData> = self.store()
        store.find(options: Options(deltaSet: deltaSetSwitch.isOn)) {
            self.endDate = Date()
            let count: Int
            switch $0 {
            case .success(let results):
                count = results.count
            case .failure(let error):
                print(error)
                count = 0
            }
            self.durationLabel.text = "\(self.durationLabel.text ?? "")\n\(count)"
        }
    }
    
}
