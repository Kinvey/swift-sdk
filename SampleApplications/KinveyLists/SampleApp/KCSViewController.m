//
//  KCSViewController.m
//  SampleApp
//
//  Created by Brian Wilson on 10/24/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSViewController.h"

@implementation KCSViewController
@synthesize splashImage;
@synthesize loadingText;
@synthesize loadingProgress;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSLog(@"About to do splash stuff");
    [loadingText setFont: [UIFont fontWithName:@"Lobster 1.4" size: 32.0]];
    [loadingProgress startAnimating];
    NSLog(@"Scheduling 'segueToMain' for 10 seconds past: %@ (%@)", [NSDate date], [NSDate dateWithTimeInterval:10 sinceDate:[NSDate date]]);
    [self performSelector:@selector(segueToMain) withObject:nil afterDelay:10.0];
    NSLog(@"Done with splash");
}

- (void)viewDidUnload
{
    [self setSplashImage:nil];
    [self setLoadingText:nil];
    [self setLoadingProgress:nil];
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
    [super dealloc];
}

- (void)segueToMain
{
    NSLog(@"Made it to segueToMain @ %@", [NSDate date]);
    [loadingProgress stopAnimating];
//    [self performSegueWithIdentifier:@"pushToList" sender:self];
    [[self view] removeFromSuperview];

}

@end
