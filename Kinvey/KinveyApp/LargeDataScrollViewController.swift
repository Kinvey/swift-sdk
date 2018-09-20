//
//  LargeDataScroll.swift
//  Kinvey
//
//  Created by Victor Hugo on 2017-08-02.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import Kinvey

class LargeDataScrollViewController: UITableViewController {
    
    lazy var dataStore = try! DataStore<HierarchyCache>.collection(.sync)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        Kinvey.sharedClient.initialize(
            appKey: "",
            appSecret: ""
        ) { (result: Result<User?, Swift.Error>) in
            switch result {
            case .success(_):
                self.login()
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func login() {
        if Kinvey.sharedClient.activeUser == nil {
            User.login(
                username: "ccalato",
                password: "ccalato",
                options: nil
            ) { (result: Result<User, Swift.Error>) in
                switch result {
                case .success(_):
                    self.fetchData()
                case .failure(let error):
                    print(error)
                }
            }
        } else {
            fetchData()
        }
    }
    
    var data: AnyRandomAccessCollection<HierarchyCache>? {
        didSet {
            tableView.reloadData()
        }
    }
    
    func fetchData() {
        dataStore.find(options: nil) { (result: Result<AnyRandomAccessCollection<HierarchyCache>, Swift.Error>) in
            switch result {
            case .success(let data):
                self.data = data
            case .failure(let error):
                print(error)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let data = data else {
            return 0
        }
        
        return Int(data.count)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        
        guard let data = data else {
            fatalError()
        }
        
        guard let textLabel = cell.textLabel else {
            fatalError()
        }
        
        guard let detailTextLabel = cell.detailTextLabel else {
            fatalError()
        }
        
        let item = data[indexPath.row]
        textLabel.text = "\(item.sapCustomerNumber!) \(item.materialNumber!)"
        detailTextLabel.text = "\(item.price!) \(item.currency!)"
        
        return cell
    }
    
}
