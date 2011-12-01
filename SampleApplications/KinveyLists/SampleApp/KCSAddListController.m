//
//  KCSAddListController.m
//  KinveyLists
//
//  Created by Brian Wilson on 11/20/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSAddListController.h"
#import "KCSList.h"

@implementation KCSAddListController

@synthesize delegate=_delegate;
@synthesize viewShiftedForKeyboard=_viewShiftedForKeyboard;
@synthesize keyboardShiftAmount=_keyboardShiftAmount;
@synthesize keyboardSlideDuration=_keyboardSlideDuration;
@synthesize addedList=_newList;
@synthesize addedListName = _newListName;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
//- (void)viewDidLoad
//{
//    [super viewDidLoad];
//}


- (void)viewDidUnload
{
    [self setAddedListName:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewUpForKeyboard:)
                                                 name: UIKeyboardWillShowNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(shiftViewDownAfterKeyboard)
                                                 name: UIKeyboardWillHideNotification
                                               object: nil];
    
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardWillShowNotification
                                                  object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UIKeyboardWillHideNotification
                                                  object: nil];
    
}

// Make the keyboard display properly
- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    CGRect keyboardFrame;
    NSDictionary* userInfo = theNotification.userInfo;
    self.keyboardSlideDuration = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    keyboardFrame = [[userInfo objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIInterfaceOrientation theStatusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if UIInterfaceOrientationIsLandscape(theStatusBarOrientation)
        self.keyboardShiftAmount = keyboardFrame.size.width / 2.0;
    else 
        self.keyboardShiftAmount = keyboardFrame.size.height / 2.0;
    
    [UIView beginAnimations: @"ShiftUp" context: nil];
    [UIView setAnimationDuration: self.keyboardSlideDuration];
    self.view.center = CGPointMake( self.view.center.x, self.view.center.y - self.keyboardShiftAmount);
    [UIView commitAnimations];
    self.viewShiftedForKeyboard = TRUE;
}

//------------------

- (void) shiftViewDownAfterKeyboard;
{
    if (self.viewShiftedForKeyboard)
    {
        [UIView beginAnimations: @"ShiftUp" context: nil];
        [UIView setAnimationDuration: self.keyboardSlideDuration];
        self.view.center = CGPointMake( self.view.center.x, self.view.center.y + self.keyboardShiftAmount);
        [UIView commitAnimations];
        self.viewShiftedForKeyboard = FALSE;
    }
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)cancel:(id)sender
{
    NSLog(@"Got cancel request: %@", sender);
    self.addedList = nil;
	[self.delegate detailsViewControllerDidCancel:self];
}
- (IBAction)done:(id)sender
{
    NSLog(@"Got done request: %@", sender);
    self.addedList = [[[KCSList alloc] initWithName:self.addedListName.text withList:nil] autorelease];
	[self.delegate detailsViewControllerDidSave:self];
}

// Make the Keyboard go away
- (BOOL)textFieldShouldReturn: (UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


                    - (void)dealloc {
                        [_newListName release];
                        [super dealloc];
                    }
@end
