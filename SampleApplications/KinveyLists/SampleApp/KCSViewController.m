//
//  KCSViewController.m
//  SampleApp
//
//  Created by Brian Wilson on 10/24/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSViewController.h"
#import "KCSListOverviewTableController.h"
#import "KCSAppDelegate.h"
#import "KCSList.h"
#import <KinveyKit/KinveyKit.h>

@implementation KCSViewController
@synthesize splashImage;
@synthesize loadingText;
@synthesize loadingProgress;
@synthesize listButton;

@synthesize listsCollection=_listsCollection;
@synthesize kLists=_kLists;


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.listsCollection){
        return;
    }
    // Do any additional setup after loading the view, typically from a nib.
    self.navigationController.navigationBarHidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES   
                                            withAnimation:UIStatusBarAnimationSlide];

    NSLog(@"About to do splash stuff");
    [loadingText setFont: [UIFont fontWithName:@"Lobster 1.4" size: 32.0]];
    [loadingProgress startAnimating];
    NSLog(@"Done with splash");
    self.listsCollection = [[KCSClient sharedClient] collectionFromString:@"lists" withClass:[KCSList class]];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self.listsCollection fetchAllWithDelegate:self];
}

- (void)viewDidUnload
{
    [self setSplashImage:nil];
    [self setLoadingText:nil];
    [self setLoadingProgress:nil];
    [self setListButton:nil];
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
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)dealloc {
    [splashImage release];
    [loadingText release];
    [loadingProgress release];
    [listButton release];
    [super dealloc];
}

- (void)segueToMain
{
    NSLog(@"Made it to segueToMain @ %@", [NSDate date]);
    [loadingProgress stopAnimating];
    [loadingProgress setHidesWhenStopped:YES];
//    [self.listButton setUserInteractionEnabled:YES];
//    [self.listButton setHidden:NO];
    [self.loadingText setHidden:YES];
    [self performSegueWithIdentifier:@"pushToMain" sender:self];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSLog(@"Segue: %@", segue.identifier);
    if ([segue.identifier isEqualToString:@"pushToMain"]){
        KCSListOverviewTableController *nextViewController = segue.destinationViewController;
        nextViewController.kLists = [NSMutableArray arrayWithArray:self.kLists];
        
    }
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    NSLog(@"Update failed: %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    UIAlertView *alert =
    [[UIAlertView alloc] initWithTitle: @"Error Downloading Lists"
                               message: [error description]
                              delegate: self
                     cancelButtonTitle: @"OK"
                     otherButtonTitles: nil];
    [alert show];
    [alert release];
    [self segueToMain];

}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
//    NSArray *res = (NSArray *)result;
//    NSLog(@"Got successfull fetch response: %@", res);
    //    NSLog(@"Number of elements: %@", res.count);
    
    self.kLists = [NSMutableArray arrayWithArray:(NSArray *)result];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self segueToMain];
}

@end
