//
//  ViewController.h
//  OfflineTester
//
//  Created by Michael Katz on 8/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (retain, nonatomic) IBOutlet UILabel *nSavesLabel;
- (IBAction)addSave:(id)sender;

@end
