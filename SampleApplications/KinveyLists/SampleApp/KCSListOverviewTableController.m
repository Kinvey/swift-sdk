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
#import "KCSAddListController.h"
#import "KCSDeleteHelper.h"
#import <KinveyKit/KinveyKit.h>


@implementation KCSListOverviewTableController

@synthesize kLists          = _kLists;
@synthesize listsCollection = _listsCollection;
@synthesize listToAdd       = _listToAdd;
@synthesize deleteHelper    = _deleteHelper;

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
    NSLog(@"Updating Data");
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.listsCollection fetchAllWithDelegate:self];
}

#pragma mark - View lifecycl


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;

    // Prepare for syncing with Kinvey...
    if (self.listsCollection == nil){
        self.listsCollection = [[KCSClient sharedClient] collectionFromString:@"lists" withClass:[KCSList class]];
        _deleteHelper = [[KCSDeleteHelper deleteHelper] retain];
    }

    if (self.kLists == nil){
        [self updateData];
    }

    
    [[UIApplication sharedApplication] setStatusBarHidden:NO   
                                            withAnimation:UIStatusBarAnimationSlide];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.hidesBackButton = YES;

//    NSLog(@"Hey, at least the view loaded... %@", self.kLists);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [_deleteHelper release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateData];
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
//    NSLog(@"KLists is messed up... %@", self.kLists);
//    NSLog(@"Number of rows... %d", self.kLists.count);
    return self.kLists.count;

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
//    NSLog(@"Cell of interest: %@", cellList);
//    NSLog(@"Cell of interest Name: %@", cellList.name);
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


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        // Delete the subcollection
        // Delete the row from the data source
        KCSList *entry = [self.kLists objectAtIndex:indexPath.row];
        [self.deleteHelper removeItemsFromList:entry.name withListID:entry.listId];
        [entry deleteFromCollection:self.listsCollection withDelegate:self];
        
//        NSLog(@"Klists Bfore: %@", self.kLists);        
        [self.kLists removeObjectAtIndex:indexPath.row];
//        NSLog(@"Klists After: %@", self.kLists);
        
        // Delete the collection?
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//    }   
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
    if ([segue.identifier isEqualToString:@"pushToList"]){
        NSLog(@"Segue pushToList called...");
        KCSListContentTableController *content = segue.destinationViewController;
        content.listName = [[self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row] name];
        content.listId = [[self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row] listId];
//        content.listContents = [self.kLists objectAtIndex: self.tableView.indexPathForSelectedRow.row];
    } else if ([segue.identifier isEqualToString:@"addList"])	{
        NSLog(@"Ok, i'm in the right spot");
		KCSAddListController *addListController = segue.destinationViewController;
//		KCSAddListController *addListController = [[navigationController viewControllers] objectAtIndex:0];
		addListController.delegate = self;
	}
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    NSLog(@"Update failed: %@", error);
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle: @"Error getting collection"
                               message: [error description]
                              delegate: self
                     cancelButtonTitle: @"OK"
                     otherButtonTitles: nil];
    [alert show];
    [alert release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
//    NSArray *res = (NSArray *)result;
//    NSLog(@"Got successfull fetch response: %@", res);
//    NSLog(@"Number of elements: %@", res.count);
    
    self.kLists = [NSMutableArray arrayWithArray:(NSArray *)result];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [(UITableView *)self.view reloadData];
}

#pragma mark - PlayerDetailsViewControllerDelegate

- (void)detailsViewControllerDidCancel:(UIViewController *)controller
{
    NSLog(@"Caught cancel request, self: %@, controller: %@", self, controller);
	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)detailsViewControllerDidSave:(UIViewController *)controller
{
    NSLog(@"Attempting to add to a list");
    KCSAddListController *alController = (KCSAddListController *)controller;
//    [alController.addedList retain];
    
    self.listToAdd = alController.addedList;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.listToAdd saveToCollection:self.listsCollection withDelegate:self];
	[controller dismissViewControllerAnimated:YES completion:nil];
}


- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    NSLog(@"Result: %@", result);
    // Nil result means that we deleted.
    if (self.listToAdd == nil || result == nil){
        // We just deleted something... do nothing, just make sure view is updated
        return;
    }
    NSLog(@"List Saving worked!");
    NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.kLists.count inSection:0]];
    [self.kLists addObject:self.listToAdd];
    [[self tableView] beginUpdates];
    [[self tableView] insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationAutomatic];
    [[self tableView] endUpdates];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateData];

}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle: @"Error Saving List"
                               message: [error description]
                              delegate: self
                     cancelButtonTitle: @"OK"
                     otherButtonTitles: nil];
    [alert show];
    [alert release];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}



@end
