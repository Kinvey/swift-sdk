//
//  KCSListItemDetailController.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>


@class KCSListEntry;
@class KCSClient;


@interface KCSListItemDetailController : UITableViewController
    
@property (retain) KCSListEntry *itemDetail;

@property (retain, nonatomic) IBOutlet UITextField *itemName;
@property (retain, nonatomic) IBOutlet UITextView *itemDescription;
@property (retain, nonatomic) IBOutlet UIImageView *itemPicture;

@end
