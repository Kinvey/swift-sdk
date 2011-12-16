//
//  KCSViewController.h
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>

@class KCSClient;
@class KitTestObject;
@class KCSCollection;
@class RootViewController;

@interface KCSViewController : UIViewController <KCSPersistableDelegate, KCSCollectionDelegate, KCSInformationDelegate>

// Kinvey Note: This is moving to be a Singleton in KinveyKit, so this code will not be necessary in the next release
@property (retain) KCSCollection *testObjects;
@property (retain) KitTestObject *testObject;
@property (readwrite) int collectionCount;
@property (readwrite) int currentTest;
@property (retain) KitTestObject *lastObject;

@property (retain) RootViewController *rootViewController;

// UI Stuff
@property BOOL viewShiftedForKeyboard;
@property NSTimeInterval keyboardSlideDuration;
@property CGFloat keyboardShiftAmount;


@property (retain, nonatomic) IBOutlet UILabel *lastName;
@property (retain, nonatomic) IBOutlet UILabel *lastCount;
@property (retain, nonatomic) IBOutlet UILabel *lastObjectId;
@property (retain, nonatomic) IBOutlet UILabel *currentCount;
@property (retain, nonatomic) IBOutlet UITextField *updatedName;
@property (retain, nonatomic) IBOutlet UITextField *updatedCount;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *networkActivity;


- (IBAction)refreshData:(id)sender;
- (IBAction)populateData:(id)sender;
- (IBAction)addEntry:(id)sender;
- (IBAction)updateEntry:(id)sender;
- (IBAction)deleteLast:(id)sender;
- (IBAction)flipView:(id)sender;

- (void)prepareDataForView;


@end
