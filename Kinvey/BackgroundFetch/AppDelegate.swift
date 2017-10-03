//
//  AppDelegate.swift
//  BackgroundFetch
//
//  Created by Victor Hugo on 2017-09-22.
//  Copyright © 2017 Kinvey. All rights reserved.
//

import UIKit
import Kinvey
import PromiseKit

class Book: Entity {
    
    dynamic var name: String?
    
    override class func collectionName() -> String {
        return "Book"
    }
    
    override func propertyMapping(_ map: Map) {
        super.propertyMapping(map)
        
        name <- ("name", map["name"])
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        Kinvey.sharedClient.initialize(
//            appKey: "",
//            appSecret: ""
//        ) { (result: Kinvey.Result<User?, Swift.Error>) in
//            switch result {
//            case .success(let user):
//                if let user = user {
//                    print(user)
//                } else {
//                    self.signup()
//                }
//            case .failure(let error):
//                print(error)
//            }
//        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        return true
    }
    
    func signup() {
        User.signup(options: nil) { (result: Kinvey.Result<User, Swift.Error>) in
            switch result {
            case .success(let user):
                print(user)
            case .failure(let error):
                print(error)
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    lazy var dataStore = DataStore<Book>.collection(.network)
    
    lazy var fileStore = FileStore()

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("background fetch")
        
        var promises = [AnyPromise]()
        
        let promiseDataStore = Promise<AnyRandomAccessCollection<Book>> { fulfill, reject in
            print("DataStore find")
            self.dataStore.find { (result: Kinvey.Result<AnyRandomAccessCollection<Book>, Swift.Error>) in
                switch result {
                case .success(let books):
                    print("\(books.count) Book(s)")
                    fulfill(books)
                case .failure(let error):
                    print(error)
                    reject(error)
                }
            }
        }
        promises.append(AnyPromise(promiseDataStore))
        
        let promiseFileStore = Promise<[File]> { fulfill, reject in
            print("Files find")
            self.fileStore.find(options: nil) { (result: Kinvey.Result<[File], Swift.Error>) in
                switch result {
                case .success(let files):
                    print("\(files.count) File(s)")
                    fulfill(files)
                case .failure(let error):
                    print(error)
                    reject(error)
                }
            }
        }
        promises.append(AnyPromise(promiseFileStore))
        
        when(fulfilled: promises.map { $0.asPromise() }).then { (result) -> Void in
            print("completionHandler new data")
            completionHandler(.newData)
        }.catch { (error) -> Void in
            print("completionHandler failed")
            completionHandler(.failed)
        }
    }

}

