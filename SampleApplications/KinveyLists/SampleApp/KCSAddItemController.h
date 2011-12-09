//
//  KCSAddItem.h
//  KinveyLists
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KCSTableViewControllerAddDelegate.h"

@class KCSListEntry;
@interface KCSAddItemController : UITableViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (retain) id<KCSTableViewControllerAddDelegate> delegate;

// UI Stuff
@property BOOL viewShiftedForKeyboard;
@property NSTimeInterval keyboardSlideDuration;
@property CGFloat keyboardShiftAmount;
@property (nonatomic, retain) UIImage *defaultImage;

@property (nonatomic, retain) UIImagePickerController *imagePicker;
@property (nonatomic, retain) UIImage *selectedImage;

@property (nonatomic, retain) KCSListEntry *addedEntry;

@property BOOL hasSelectedImage;
@property (retain, nonatomic) UIBarButtonItem *addButton;
@property (retain, nonatomic) UIBarButtonItem *doneButton;
@property (retain, nonatomic) UIBarButtonItem *updateButton;
@property (retain, nonatomic) UIBarButtonItem *cancelButton;

//@property (retain) KCSList *addedList;

@property (retain, nonatomic) IBOutlet UITextField *itemNameToAdd;
@property (retain, nonatomic) IBOutlet UITextView *itemDescriptionToAdd;
@property (retain, nonatomic) IBOutlet UIButton *imageButton;

@property (nonatomic) BOOL isUpdateView;


- (IBAction)cancel:(id)sender;
- (IBAction)done:(id)sender;
- (IBAction)addImage:(id)sender;

@end
