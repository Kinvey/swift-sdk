//
//  ImageViewController.h
//  KitTest
//
//  Created by Brian Wilson on 11/16/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>

@class RootViewController;

@interface ImageViewController : UIViewController <KCSResourceDelegate>
@property (retain) KCSClient *kinveyClient;
@property (retain, nonatomic) IBOutlet UIImageView *ourImage;
@property (retain, nonatomic) IBOutlet UILabel *imageName;
@property (retain, nonatomic) IBOutlet UILabel *imageState;
@property (retain) NSString *currentOperation;

@property (retain) RootViewController *rootViewController;

- (IBAction)uploadImage:(id)sender;
- (IBAction)deleteImage:(id)sender;
- (IBAction)refreshImage:(id)sender;
- (IBAction)flipView:(id)sender;

@end
