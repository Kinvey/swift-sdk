//
//  KCSListContentTableController.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>

@interface KCSListContentTableController : UITableViewController <KCSCollectionDelegate, KCSPersistDelegate>

@property (retain) NSString *listName;
@property (retain) NSMutableArray *listContents;
@property (retain) KCSCollection *listItemsCollection;
@property (retain) NSString *listId;


@end
