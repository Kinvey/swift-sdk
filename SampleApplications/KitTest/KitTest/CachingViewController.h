//
//  CachingViewController.h
//  KitTest
//
//  Created by Michael Katz on 5/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CachingViewController : UIViewController <UITableViewDataSource> {
    id objects;
}
@property (retain, nonatomic) IBOutlet UILabel *countLabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *cachePolicy;
- (IBAction)performQuery:(id)sender;
- (IBAction)selectPolicy:(id)sender;
@property (retain, nonatomic) IBOutlet UISwitch *nameSwitch;

@property (retain, nonatomic) IBOutlet UITableView *tableView;
@property (retain, nonatomic) IBOutlet UIProgressView *progressView;
@property (retain, nonatomic) IBOutlet UIButton *queryButton;
- (IBAction)groupByName:(id)sender;

@end
