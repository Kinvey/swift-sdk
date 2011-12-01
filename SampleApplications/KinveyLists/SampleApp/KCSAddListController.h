//
//  KCSAddListController.h
//  KinveyLists
//
//  Created by Brian Wilson on 11/20/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCSTableViewControllerAddDelegate.h"

@class KCSList;

@interface KCSAddListController : UIViewController

@property (retain) id<KCSTableViewControllerAddDelegate> delegate;
// UI Stuff
@property BOOL viewShiftedForKeyboard;
@property NSTimeInterval keyboardSlideDuration;
@property CGFloat keyboardShiftAmount;

@property (retain) KCSList *addedList;

@property (retain, nonatomic) IBOutlet UITextField *addedListName;


- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;


@end
