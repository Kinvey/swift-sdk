//
//  KCSListContentTableController.m
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSListContentTableController.h"
#import "KCSListItemDetailController.h"
#import "KCSAppDelegate.h"
#import "KCSListEntry.h"



@implementation KCSListContentTableController

@synthesize listContents=_listContents;
@synthesize listName=_listName;
@synthesize kinveyClient=_kinveyClient;
@synthesize listItemsCollection=_listItemsCollection;
@synthesize listId=_listId;


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.listContents = nil;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)updateData
{
    [self.listItemsCollection collectionDelegateFetch:self];
   
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    if (self.kinveyClient == nil){
        KCSAppDelegate *app = (KCSAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.kinveyClient = [app kinveyClient];
    }

    self.navigationItem.title = self.listName;
    
    // We've got a list name, we now need to get a listContents
    if ([self listItemsCollection] == nil){
        self.listItemsCollection = [[KCSCollection alloc] init];
        self.listItemsCollection.collectionName = @"list-items";
        self.listItemsCollection.objectTemplate = [[KCSListEntry alloc] init];
        self.listItemsCollection.kinveyClient = self.kinveyClient;
        [self.listItemsCollection addFilterCriteriaForProperty:@"list" withStringValue:self.listId filteredByOperator:KCS_EQUALS_OPERATOR];
    }

    [self updateData];
    
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
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return self.listContents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ListCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    // Configure the cell...
    cell.textLabel.text = [[self.listContents objectAtIndex:[indexPath row]] name];
    
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        KCSListEntry *entry = [self.listContents objectAtIndex:indexPath.row];
        [entry deleteDelegate:self usingClient:self.kinveyClient];

        [self.listContents removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


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
    if ([segue.identifier isEqualToString:@"pushToDetail"]){
        NSLog(@"Segue pushToDetail called...");
        KCSListItemDetailController *content = segue.destinationViewController;
        content.itemDetail = [self.listContents objectAtIndex: self.tableView.indexPathForSelectedRow.row];
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
    
    self.listContents = [NSMutableArray arrayWithArray:(NSArray *)result];
    [self.view reloadData];
}

- (void)persistDidFail:(id)error
{
    NSLog(@"Persist failed: %@", error);
}

- (void)persistDidComplete:(NSObject *)result
{
    NSLog(@"Persist succeeded: %@", (NSURLResponse *)result);
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)[[self kinveyClient] lastResponse];
    NSDictionary *headers = [res allHeaderFields];
//    NSLog(@"Response code: %@, Headers: %@", res.statusCode, headers);
    
    
}





@end
