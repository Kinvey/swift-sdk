//
//  CachingViewController.h
//  KitTest
//
//  Created by Michael Katz on 5/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CachingViewController : UIViewController
@property (retain, nonatomic) IBOutlet UILabel *countLabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *cachePolicy;
- (IBAction)performQuery:(id)sender;
- (IBAction)selectPolicy:(id)sender;

@end
