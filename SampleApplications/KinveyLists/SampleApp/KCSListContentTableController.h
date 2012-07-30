//
//  KCSListContentTableController.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>
#import "KCSTableViewControllerAddDelegate.h"

@class KCSListEntry;
@interface KCSListContentTableController : UITableViewController <KCSCollectionDelegate, KCSPersistableDelegate, KCSTableViewControllerAddDelegate, KCSResourceDelegate>

@property (retain) NSString *listName;
@property (retain) NSMutableArray *listContents;
@property (retain) KCSCollection *listItemsCollection;
@property (retain) NSString *listId;

@property (retain) KCSListEntry *entryBeingAdded;
@property (nonatomic) BOOL isDetailUpdate;


@end
