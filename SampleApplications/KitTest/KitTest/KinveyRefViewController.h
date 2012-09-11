//
//  ViewController.h
//  KitTest
//
//  Created by Michael Katz on 9/7/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KinveyRefViewController : UIViewController
@property (retain, nonatomic) IBOutlet UIButton *one;
@property (retain, nonatomic) IBOutlet UIButton *two;
@property (retain, nonatomic) IBOutlet UIButton *three;
@property (retain, nonatomic) IBOutlet UIButton *four;
@property (retain, nonatomic) IBOutlet UIButton *a;
@property (retain, nonatomic) IBOutlet UIButton *b;
@property (retain, nonatomic) IBOutlet UIButton *c;
@property (retain, nonatomic) IBOutlet UIButton *d;
- (IBAction)save:(id)sender;
@property (retain, nonatomic) IBOutlet UIButton *load;
- (IBAction)doOne:(id)sender;
- (IBAction)load:(id)sender;
- (IBAction)doTwo:(id)sender;
- (IBAction)doThree:(id)sender;
- (IBAction)doFour:(id)sender;
- (IBAction)doA:(id)sender;
- (IBAction)doB:(id)sender;
- (IBAction)doD:(id)sender;

- (IBAction)doC:(id)sender;

- (IBAction)clear:(id)sender;
@end
