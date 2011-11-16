//
//  KCSListOverviewTableController.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KinveyKit.h"

@interface KCSListOverviewTableController : UITableViewController <KCSCollectionDelegate>

@property (retain) NSMutableArray *kLists;
@property (retain) KCSClient *kinveyClient;
@property (retain) KCSCollection *listsCollection;

@end
