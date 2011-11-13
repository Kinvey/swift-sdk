//
//  KCSListOverviewTableController.m
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSListOverviewTableController.h"
#import "KCSListContentTableController.h"
#import "KCSList.h"
#import "KCSListEntry.h"
#import "KCSAppDelegate.h"
#import "KinveyCollection.h"

@implementation KCSListOverviewTableController

@synthesize kLists=_kLists;
@synthesize kinveyClient=_kinveyClient;
@synthesize listsCollection=_listsCollection;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void) updateData
{
    [self.listsCollection collectionDelegateFetchAll:self];
}

#pragma mark - View lifecycl

- (void)initStaticList
{
    [self.kLists addObject:[[KCSList alloc] initWithName:@"Kinvey -- Costco" 
                                                withList:[NSMutableArray arrayWithObjects:
                                                          [[KCSListEntry alloc] initWithName:@"Granola Bars" withDescription:@"Very tasty treats to be eating"],
                                                          [[KCSListEntry alloc] initWithName:@"Gum" withDescription:@"For chewing, you know, like gum? Should be available at 1 Cambridge Center, Cambridge, MA"],
                                                          [[KCSListEntry alloc] initWithName:@"Beer" withDescription:@"Chug! Chug! Chug! Chug! Chug! Check Pretty Things (www.prettythingsbeertoday.com)"],
                                                          [[KCSListEntry alloc] initWithName:@"Cristal" withDescription:@"When only the finest will do, cold cocked!"], nil]]];
    
    [self.kLists addObject:[[KCSList alloc] initWithName:@"Brian -- Apple Store"
                                                withList:[NSMutableArray arrayWithObjects:
                                                          [[KCSListEntry alloc] initWithName:@"MiniDP to DVI" withDescription:@"To go from my lap to my face"],
                                                          [[KCSListEntry alloc] initWithName:@"iPhone" withDescription:@"Hey, aren't we using this technology now?"],
                                                          [[KCSListEntry alloc] initWithName:@"Cinema Display" withDescription:@"Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda. Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda."],
                                                          nil]]];    
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Prepare for syncing with Kinvey...
    if (self.kinveyClient == nil){
        KCSAppDelegate *app = (KCSAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.kinveyClient = [app kinveyClient];
        self.listsCollection = [[KCSCollection alloc] init];
        self.listsCollection.kinveyClient = self.kinveyClient;
        self.listsCollection.objectTemplate = [[KCSList alloc] init];
        self.listsCollection.collectionName = @"lists";
    }
    
    [self updateData];
    
    NSLog(@"Hey, at least the view loaded... %@", self.kLists);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSLog(@"numberOfSectionsInTableView");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSLog(@"KLists is messed up... %@", self.kLists);
    NSLog(@"Number of rows... %d", self.kLists.count);
    return self.kLists.count;
//    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListCollectionCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...

    KCSList *cellList = [self.kLists objectAtIndex:[indexPath row]];
    NSLog(@"Cell of interest: %@", cellList);
    NSLog(@"Cell of interest Name: %@", cellList.name);
    cell.textLabel.text = cellList.name;
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pushToList"]){
        NSLog(@"Segue pushToList called...");
        KCSListContentTableController *content = segue.destinationViewController;
        content.listName = [[self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row] name];
        content.listId = [[self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row] listId];
//        content.listContents = [self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row];
    }
}

- (void) fetchCollectionDidFail: (id)error
{
    NSLog(@"Update failed: %@", error);
}

- (void) fetchCollectionDidComplete: (NSObject *) result
{
    NSArray *res = (NSArray *)result;
    NSLog(@"Got successfull fetch response: %@", res);
//    NSLog(@"Number of elements: %@", res.count);
    
    self.kLists = [NSMutableArray arrayWithArray:(NSArray *)result];
    [self.view reloadData];
}




@end
