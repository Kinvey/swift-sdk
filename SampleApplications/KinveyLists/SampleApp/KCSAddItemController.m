//
//  KCSAddItem.m
//  KinveyLists
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSAddItemController.h"
#import "UIImage+Extra.h"
#import "KCSListEntry.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface KCSAddItemController()
@property BOOL imageNeedsSaved;
@property BOOL keyboadShouldSlide;
@end

@implementation KCSAddItemController
@synthesize itemNameToAdd;
@synthesize itemDescriptionToAdd;
@synthesize imageButton;

@synthesize imagePicker=_imagePicker;
@synthesize selectedImage=_selectedImage;
@synthesize viewShiftedForKeyboard=_viewShiftedForKeyboard;
@synthesize keyboardShiftAmount=_keyboardShiftAmount;
@synthesize keyboardSlideDuration=_keyboardSlideDuration;
@synthesize defaultImage=_defaultImage;
@synthesize delegate=_delegate;
@synthesize imageNeedsSaved=_imageNeedsSaved;
@synthesize keyboadShouldSlide=_keyboadShouldSlide;
@synthesize addedEntry=_addedEntry;
@synthesize addButton=_addButton;
@synthesize doneButton=_doneButton;
@synthesize cancelButton=_cancelButton;
@synthesize updateButton=_updateButton;
@synthesize isUpdateView=_isUpdateView;

@synthesize hasSelectedImage=_hasSelectedImage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.keyboadShouldSlide = YES;
    self.hasSelectedImage = NO;
    self.selectedImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                           pathForResource:@"logo114"
                                                           ofType:@"png"]];
    self.doneButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(textViewShouldReturn)] autorelease];

    self.updateButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(doneWrapper)] autorelease];
//    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBar target:self action:@selector(doneWrapper)];

    if (self.isUpdateView){
        self.addButton = self.updateButton;
        self.navigationItem.rightBarButtonItem = self.updateButton;
        self.navigationItem.leftBarButtonItem = self.navigationItem.backBarButtonItem;
        self.itemNameToAdd.text = self.addedEntry.name;
        self.itemDescriptionToAdd.text = self.addedEntry.itemDescription;
        
        if (self.addedEntry.hasCustomImage){
            self.selectedImage = self.addedEntry.loadedImage;
        }
    } else {
        self.addButton = self.navigationItem.rightBarButtonItem;
    }

}

- (void)viewDidUnload
{
    [self setItemNameToAdd:nil];
    [self setItemDescriptionToAdd:nil];
    [self setImageButton:nil];
    [_defaultImage release];
    [_doneButton release];
    [_updateButton release];
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTextViewButton:)
                                                  name:UITextViewTextDidBeginEditingNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(unsetTextViewButton:)
                                                 name:UITextViewTextDidEndEditingNotification
                                               object:nil];
    
    
    // Make our button pretty
    CGRect buttonRect = [self.imageButton contentRectForBounds:self.imageButton.bounds];
    
    [self.imageButton setImage:[self.selectedImage imageByScalingProportionallyToSize:buttonRect.size]  forState:UIControlStateNormal];
    self.imageButton.contentMode = UIViewContentModeScaleAspectFit;
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
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UITextViewTextDidBeginEditingNotification
                                                  object: nil];
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                    name: UITextViewTextDidEndEditingNotification
                                                  object: nil];
    
}


- (void)setTextViewButton: (NSNotification *)theNotification
{
    // Make the new "button" show up
    self.navigationItem.rightBarButtonItem = self.doneButton;
}

- (void)unsetTextViewButton: (NSNotification *)theNotification
{    
    // Make sure the button switches
    self.navigationItem.rightBarButtonItem = self.addButton;
}

// Make the keyboard display properly
- (void) shiftViewUpForKeyboard: (NSNotification*) theNotification;
{
    if (!self.keyboadShouldSlide){return;}

    CGRect keyboardFrame;
    NSDictionary* userInfo = theNotification.userInfo;
    self.keyboardSlideDuration = [[userInfo objectForKey: UIKeyboardAnimationDurationUserInfoKey] floatValue];
    keyboardFrame = [[userInfo objectForKey: UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIInterfaceOrientation theStatusBarOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if UIInterfaceOrientationIsLandscape(theStatusBarOrientation)
        self.keyboardShiftAmount = keyboardFrame.size.width / 4.0;
    else 
        self.keyboardShiftAmount = keyboardFrame.size.height / 4.0;
    
    [UIView beginAnimations: @"ShiftUp" context: nil];
    [UIView setAnimationDuration: self.keyboardSlideDuration];
    self.view.center = CGPointMake( self.view.center.x, self.view.center.y - self.keyboardShiftAmount);
    [UIView commitAnimations];
    self.viewShiftedForKeyboard = TRUE;
}

//------------------

- (void) shiftViewDownAfterKeyboard;
{

    if (!self.keyboadShouldSlide){return;}
    
    if (self.viewShiftedForKeyboard)
    {
        [UIView beginAnimations: @"ShiftUp" context: nil];
        [UIView setAnimationDuration: self.keyboardSlideDuration];
        self.view.center = CGPointMake( self.view.center.x, self.view.center.y + self.keyboardShiftAmount);
        [UIView commitAnimations];
        self.viewShiftedForKeyboard = FALSE;
    }
}



- (void)textFieldDidBeginEditing:(UITextField *)textField
{	
    self.keyboadShouldSlide = NO;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.keyboadShouldSlide = YES;
}

- (void)textViewShouldReturn
{
    [self.itemDescriptionToAdd resignFirstResponder];
}

    // Make the Keyboard go away
- (BOOL)textFieldShouldReturn: (UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)dealloc {
    [itemNameToAdd release];
    [itemDescriptionToAdd release];
    [imageButton release];
    [super dealloc];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0){
        [self.itemNameToAdd becomeFirstResponder];
    } else if (indexPath.section == 1){
        [self.itemDescriptionToAdd becomeFirstResponder];
    } else if (indexPath.section == 2){
        [self.imageButton becomeFirstResponder];
    }
}

- (IBAction)addImage:(id)sender {
    self.imagePicker = [[[UIImagePickerController alloc] init] autorelease];
    self.imagePicker.delegate = self;
    
    // Todo, optional
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imageNeedsSaved = YES;
    } else {
        self.imageNeedsSaved = NO;
        self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }

    self.imagePicker.mediaTypes = [NSArray arrayWithObjects: (NSString *) kUTTypeImage, nil];
    self.imagePicker.allowsEditing = NO;
    [self presentModalViewController: self.imagePicker animated: YES];
//    [self presentModalViewController:self.imagePicker animated:YES];
        
}

- (IBAction)cancel:(id)sender
{
    NSLog(@"Got cancel request: %@", sender);
//    self.addedList = nil;
	[self.delegate detailsViewControllerDidCancel:self];
}

- (void)doneWrapper
{
    [self done:self.updateButton];
}

- (IBAction)done:(id)sender
{
    NSLog(@"Got done request: %@", sender);
    if (!self.isUpdateView){
        self.addedEntry = [[[KCSListEntry alloc] initWithName:self.itemNameToAdd.text withDescription:self.itemDescriptionToAdd.text] autorelease];
        
        self.addedEntry.image = [NSString stringWithFormat:@"%@.png", [self.itemNameToAdd.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
        self.addedEntry.loadedImage = self.selectedImage;
        self.addedEntry.hasCustomImage = self.hasSelectedImage;
    } else {
        if (self.hasSelectedImage){
            self.addedEntry.hasCustomImage = self.hasSelectedImage;
            self.addedEntry.image = [NSString stringWithFormat:@"%@.png", [self.itemNameToAdd.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
            self.addedEntry.loadedImage = self.selectedImage;
        } else {
            if (![self.addedEntry.name isEqualToString:self.itemNameToAdd.text] && self.addedEntry.hasCustomImage){
                // We need to "copy" the image to a new name.
                self.addedEntry.image = [NSString stringWithFormat:@"%@.png", [self.itemNameToAdd.text stringByReplacingOccurrencesOfString:@" " withString:@""]];
            }
        }
        self.addedEntry.itemDescription = self.itemDescriptionToAdd.text;
        self.addedEntry.name            = self.itemNameToAdd.text;
    }
        
    
//    self.addedList = [[[KCSList alloc] initWithName:self.addedListName.text withList:nil] autorelease];
	[self.delegate detailsViewControllerDidSave:self];
}


#pragma mark -
#pragma mark implementation UIImagePickerDelegate

// For responding to the user tapping Cancel.
- (void) imagePickerControllerDidCancel: (UIImagePickerController *) picker {
    
    [self dismissModalViewControllerAnimated: YES];
    [picker release];
}

// For responding to the user accepting a newly-captured picture or movie
- (void) imagePickerController: (UIImagePickerController *) picker
 didFinishPickingMediaWithInfo: (NSDictionary *) info {
    
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToSave;
    
    // Handle a still image capture
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0)
        == kCFCompareEqualTo) {
        
        editedImage = (UIImage *) [info objectForKey:
                                   UIImagePickerControllerEditedImage];
        originalImage = (UIImage *) [info objectForKey:
                                     UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToSave = editedImage;
        } else {
            imageToSave = originalImage;
        }

        if (self.imageNeedsSaved){
            // Save the new image (original or edited) to the Camera Roll
            UIImageWriteToSavedPhotosAlbum (imageToSave, nil, nil , nil);
        }
        self.selectedImage = imageToSave;
        self.hasSelectedImage = YES;
            
    }
    
    [self dismissModalViewControllerAnimated: YES];
    [picker release];
}


@end
