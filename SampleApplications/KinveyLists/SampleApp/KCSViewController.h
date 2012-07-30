//
//  KCSViewController.h
//  SampleApp
//
//  Created by Brian Wilson on 10/24/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <KinveyKit/KinveyKit.h>
@interface KCSViewController : UIViewController <KCSCollectionDelegate>
@property (retain, nonatomic) IBOutlet UIImageView *splashImage;
@property (retain, nonatomic) IBOutlet UILabel *loadingText;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *loadingProgress;


@property (retain, nonatomic) IBOutlet UIButton *listButton;

// For initial loading
@property (retain) KCSCollection *listsCollection;
@property (retain) NSArray *kLists;


@end
