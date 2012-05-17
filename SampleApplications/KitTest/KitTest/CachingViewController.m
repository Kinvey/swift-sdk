//
//  CachingViewController.m
//  KitTest
//
//  Created by Michael Katz on 5/16/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "CachingViewController.h"

#import <KinveyKit/KinveyKit.h>

#import "KitTestObject.h"

@interface CachingViewController ()
@property (nonatomic, retain) KCSCachedStore* store;
@end

@implementation CachingViewController
@synthesize store;
@synthesize countLabel;
@synthesize cachePolicy;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Caching";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Custom initialization
    KCSCollection *collection = [[KCSClient sharedClient] collectionFromString:@"test_objects" withClass:[KitTestObject class]];
    
    self.store = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:KCSCachePolicyNone], KCSStoreKeyCachePolicy, collection, kKCSStoreKeyResource, nil]];
}

- (void)viewDidUnload
{
    [self setCountLabel:nil];
    [self setCachePolicy:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [countLabel release];
    [cachePolicy release];
    [super dealloc];
}
- (IBAction)performQuery:(id)sender {
    KCSCachePolicy policy = self.cachePolicy.selectedSegmentIndex;
    KCSQuery* q = [KCSQuery query];
    NSString* s = [q JSONStringRepresentation];
    [self.store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        self.countLabel.text = [NSString stringWithFormat:@"%d",[objectsOrNil count]];
    } withProgressBlock:nil cachePolicy:policy];
}

- (IBAction)selectPolicy:(id)sender {
}
@end
