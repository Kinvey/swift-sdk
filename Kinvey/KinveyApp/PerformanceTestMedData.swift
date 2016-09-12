//
//  PeformanceTestMedData.swift
//  Kinvey
//
//  Created by Victor Barros on 2016-04-20.
//  Copyright © 2016 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class PerformanceTestMedData: PerformanceTestData {
    
    override func test() {
        startDate = NSDate()
        let store: DataStore<MedData> = self.store()
        store.find(deltaSet: deltaSetSwitch.on) { results, error in
            self.endDate = NSDate()
            self.durationLabel.text = "\(self.durationLabel.text ?? "")\n\(results?.count ?? 0)"
        }
    }
    
}
