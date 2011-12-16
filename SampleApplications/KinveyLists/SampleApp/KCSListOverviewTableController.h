//
//  KCSListOverviewTableController.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>
#import "KCSTableViewControllerAddDelegate.h"
@class KCSList;
@class KCSDeleteHelper;
@interface KCSListOverviewTableController : UITableViewController <KCSCollectionDelegate, KCSTableViewControllerAddDelegate, KCSPersistableDelegate>

@property (retain) NSMutableArray *kLists;
@property (retain) KCSCollection *listsCollection;
@property (retain) KCSList *listToAdd;
@property (retain) KCSDeleteHelper *deleteHelper;

@end
