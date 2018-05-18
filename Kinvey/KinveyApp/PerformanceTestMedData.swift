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
        startDate = Date()
        let store: DataStore<MedData> = self.store()
        store.find(options: Options(deltaSet: deltaSetSwitch.isOn)) { (result: Result<AnyRandomAccessCollection<MedData>, Swift.Error>) in
            self.endDate = Date()
            switch result {
            case .success(let results):
                self.durationLabel.text = "\(self.durationLabel.text ?? "")\n\(results.count)"
            case .failure(let error):
                self.durationLabel.text = "\(self.durationLabel.text ?? "")\nError: \(error.localizedDescription)"
            }
        }
    }
    
}
