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
#import "KCSAddItemController.h"
#import "KCSAppDelegate.h"



@implementation KCSListContentTableController

@synthesize listContents        = _listContents;
@synthesize listName            = _listName;
@synthesize listItemsCollection = _listItemsCollection;
@synthesize listId              = _listId;
@synthesize entryBeingAdded     = _entryBeingAdded;
@synthesize isDetailUpdate      = _isDetailUpdate;

- (id)init
{
    NSLog(@"******************************************");
    self = [super init];
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.isDetailUpdate = NO;
        self.listContents = nil;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
    KCSAppDelegate *appDelegate = (KCSAppDelegate *)[[UIApplication sharedApplication]delegate];
    
    // Clear all of the objects from the cache...  they can be refetched
    [appDelegate.imageCache removeAllObjects];
}


- (void)updateData
{
    [self.listItemsCollection fetchWithDelegate:self];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.title = self.listName;
    self.isDetailUpdate = NO;
    
    
    // We've got a list name, we now need to get a listContents
    if ([self listItemsCollection] == nil){
        self.listItemsCollection = [[KCSClient sharedClient] collectionFromString:@"list-items" withClass:[KCSListEntry class]];
//        [self.listItemsCollection addFilterCriteriaForProperty:@"list" withStringValue:self.listId filteredByOperator:KCS_EQUALS_OPERATOR];
        self.listItemsCollection.query = [KCSQuery queryOnField:@"list" withExactMatchForValue:self.listId];
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
    KCSListEntry *ent = [self.listContents objectAtIndex:[indexPath row]];
    cell.textLabel.text = ent.name;
    cell.detailTextLabel.text = ent.itemDescription;
    
    // By default we have a default image if we've got an overridden image, then we need to set it here...
    KCSAppDelegate *appDelegate = (KCSAppDelegate *)[[UIApplication sharedApplication] delegate];
    
//    NSLog(@"Entry for Cell: %@ (Image: %@)", ent, ent.image);
    if (ent.hasCustomImage && [appDelegate.imageCache objectForKey:ent.image] != nil){
        cell.imageView.image = [appDelegate.imageCache objectForKey:ent.image];
        ent.loadedImage = cell.imageView.image;
    } else if (ent.hasCustomImage){
        [KCSResourceService downloadResource:ent.image withResourceDelegate:self];
    }
    
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
        [entry deleteFromCollection:self.listItemsCollection withDelegate:self];

        [self.listContents removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }   
//    else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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
    self.isDetailUpdate = YES;
    [self performSegueWithIdentifier:@"addItem" sender:self];
}

#pragma mark - PlayerDetailsViewControllerDelegate

- (void)detailsViewControllerDidCancel:(UIViewController *)controller
{
    NSLog(@"Caught cancel request, self: %@, controller: %@", self, controller);
    [controller.navigationController popViewControllerAnimated:YES];
    //	[controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)detailsViewControllerDidSave:(UIViewController *)controller
{
    KCSAddItemController *aiController = (KCSAddItemController *)controller;
//    [aiController.addedEntry retain];
    
    // Make sure to associate with this list...
    aiController.addedEntry.list = self.listId;
    
    //    KCSAddListController *alController = (KCSAddListController *)controller;
    //    [alController.addedList retain];
    //    
    //    self.listToAdd = alController.addedList;
    //    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //    [self.listToAdd persistDelegate:self persistToCollection:self.listsCollection];
    
    self.entryBeingAdded = aiController.addedEntry;
    
    if (self.entryBeingAdded.hasCustomImage){
        self.entryBeingAdded.image = [self.entryBeingAdded.list stringByAppendingFormat:@"-%@", self.entryBeingAdded.image];
        
        NSLog(@"Adding for Cell: %@ (Image: %@)", self.entryBeingAdded, self.entryBeingAdded.image);
        [KCSResourceService saveData:UIImagePNGRepresentation(self.entryBeingAdded.loadedImage) toResource:self.entryBeingAdded.image withDelegate:self];
        KCSAppDelegate *appDelegate = (KCSAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.imageCache setObject:self.entryBeingAdded.loadedImage forKey:self.entryBeingAdded.image];
    }
    
    
    [controller.navigationController popViewControllerAnimated:YES];

    // Persist image to blob...
    // Persist entry to kinvey
    [aiController.addedEntry saveToCollection:self.listItemsCollection withDelegate:self];
    

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    if ([segue.identifier isEqualToString:@"addItem"])	{
        NSLog(@"Ok, i'm in the right spot");
        KCSAddItemController *addItemController = segue.destinationViewController;
        //		KCSAddListController *addListController = [[navigationController viewControllers] objectAtIndex:0];
        addItemController.delegate = self;
        addItemController.isUpdateView = NO;
        if (self.isDetailUpdate){
            addItemController.isUpdateView = YES;
            addItemController.addedEntry = [self.listContents objectAtIndex: self.tableView.indexPathForSelectedRow.row];
            self.isDetailUpdate = NO;
        }
    } else if ([segue.identifier isEqualToString:@"pushToDetail"]){
        NSLog(@"Segue pushToDetail called...");
        KCSAddItemController *addItemController = segue.destinationViewController;
        addItemController.isUpdateView = YES;
        addItemController.delegate = self;
        addItemController.addedEntry = [self.listContents objectAtIndex: self.tableView.indexPathForSelectedRow.row];
        //KCSListItemDetailController *content = segue.destinationViewController;
        //content.itemDetail = [self.listContents objectAtIndex: self.tableView.indexPathForSelectedRow.row];
    }
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    NSLog(@"Update failed (Collection: %@): %@", collection, error);
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Update Failed!"
                                                     message:[error description]
                                                    delegate:self cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil] autorelease];

    [alert show];

}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
//    NSArray *res = (NSArray *)result;
//    NSLog(@"Got successfull fetch response: %@", res);
    //    NSLog(@"Number of elements: %@", res.count);
    
    self.listContents = [NSMutableArray arrayWithArray:(NSArray *)result];
    
    [(UITableView *)self.view reloadData];
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    NSLog(@"Persist failed: %@", error);
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Save Failed!"
                                                     message:[error description]
                                                    delegate:self cancelButtonTitle:@"Ok"
                                           otherButtonTitles:nil] autorelease];
    
    [alert show];

}

- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    NSLog(@"Result: %@", result);
    // Nil result means that we deleted.
    if (self.entryBeingAdded == nil || result == nil){
        // We just deleted something... do nothing, just make sure view is updated
        return;
    }
    NSArray *array = [NSArray arrayWithObject:[NSIndexPath indexPathForRow:self.listContents.count inSection:0]];
    [self.listContents addObject:self.entryBeingAdded];
    [[self tableView] beginUpdates];
    [[self tableView] insertRowsAtIndexPaths:array withRowAnimation:UITableViewRowAnimationAutomatic];
    [[self tableView] endUpdates];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self updateData];

}


- (void)resourceServiceDidFailWithError:(NSError *)error
{
    // Prevent issues later...
    self.entryBeingAdded.hasCustomImage = NO;
    NSLog(@"Upload of image failed: %@", error);

// Need to prevent alert flooding...    
//    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Saving Image Failed!"
//                                                     message:@"Using default image."
//                                                    delegate:self cancelButtonTitle:@"Ok"
//                                           otherButtonTitles:nil] autorelease];
//
//    [alert show];

}


- (void)resourceServiceDidCompleteWithResult:(KCSResourceResponse *)result
{
    UIImage *image = [UIImage imageWithData:result.resource];
    
    if (image == nil){
        // This was an upload, not a download
        NSLog(@"Image upload completed: %@", result.resourceId);
        return;
    }
    
    KCSAppDelegate *appDelegate = (KCSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.imageCache setObject:image forKey:result.resourceId];
    
    [(UITableView *)self.view reloadData];
}




@end
