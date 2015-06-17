//
//  MICViewController.swift
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

import UIKit

class MICViewController: UITableViewController {

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch (indexPath.row) {
            case 1:
                KCSClient.sharedClient().initializeKinveyServiceForAppKey(
                    "kid_W1rPs9qy0",
                    withAppSecret: "75f94ea7477c4bb7bd28c93b703bd10b",
                    usingOptions: nil
                )
                
                KCSUser.presentMICViewControllerWithMICRedirectURI(
                    "kinveyAuthDemo://",
                    withCompletionBlock: { (user: KCSUser!, error: NSError!, actionResult: KCSUserActionResult) -> Void in
                        if (user != nil) {
                            NSLog("KCSUser: \(user.username) (\(user.userId))")
                        } else if (error != nil) {
                            NSLog("NSError: \(error)")
                        }
                        
                        NSLog("KCSUserActionResult: \(actionResult.rawValue)")
                    }
                )
                break;
            default:
                assert(true, "do nothing!")
        }
    }

}
