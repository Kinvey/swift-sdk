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
@property (nonatomic, retain) id objects;
@end

@implementation CachingViewController
@synthesize nameSwitch;
@synthesize tableView;
@synthesize progressView;
@synthesize queryButton;
@synthesize store;
@synthesize countLabel;
@synthesize cachePolicy;
@synthesize objects;

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
    
    self.store = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:KCSCachePolicyNone], KCSStoreKeyCachePolicy, collection, KCSStoreKeyResource, nil]];
    self.queryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewDidUnload
{
    [self setCountLabel:nil];
    [self setCachePolicy:nil];
    [self setProgressView:nil];
    [self setNameSwitch:nil];
    [self setTableView:nil];
    [self setQueryButton:nil];
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
    [progressView release];
    [nameSwitch release];
    [tableView release];
    [queryButton release];
    [super dealloc];
}
- (IBAction)performQuery:(id)sender {
    KCSCachePolicy policy = self.cachePolicy.selectedSegmentIndex;
    self.progressView.progress = 0.;
    if (self.nameSwitch.on) {
        [self.store group:[NSArray arrayWithObject:@"name"] reduce:[KCSReduceFunction COUNT] condition:nil completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
            self.objects = valuesOrNil;
            [self.tableView reloadData];
        } progressBlock:^(NSArray *objects, double percentComplete) {
            self.progressView.progress = percentComplete;
        } cachePolicy:policy];
    } else {
        [self.store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            self.countLabel.text = [NSString stringWithFormat:@"%d",[objectsOrNil count]];
            self.objects = objectsOrNil;
            [self.tableView reloadData];
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            self.progressView.progress = percentComplete; 
        } cachePolicy:policy];
    }
}

- (IBAction)selectPolicy:(id)sender {
}

- (IBAction)groupByName:(id)sender {
    self.queryButton.titleLabel.text = ((UISwitch*)sender).on ? @"Do Group" : @"Do Query";
}

#pragma mark - Table View
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.objects isKindOfClass:[NSArray class]] ? 1 : [[self.objects fieldsAndValues] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.objects isKindOfClass:[NSArray class]] ? [self.objects count] : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.objects isKindOfClass:[NSArray class]] ? nil : [[[self.objects fieldsAndValues] objectAtIndex:section] objectForKey:@"name"];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* reuseId = @"CELL_REUSE";
    UITableViewCell* cell = [tv dequeueReusableCellWithIdentifier:reuseId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
    }
    if ([self.objects isKindOfClass:[NSArray class]]) {
        KitTestObject* obj = [self.objects objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@:%i", obj.name, obj.count];
    } else {
        KCSGroup* group = self.objects;
        NSNumber* count = [[[group fieldsAndValues] objectAtIndex:indexPath.section] objectForKey:[group returnValueKey]];
        cell.textLabel.text = [NSString stringWithFormat:@"Count = %@", count];
    }
    return cell;
}
@end
