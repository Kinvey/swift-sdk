//
//  ImageViewController.m
//  KitTest
//
//  Created by Brian Wilson on 11/16/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "ImageViewController.h"
#import "RootViewController.h"

@implementation ImageViewController

@synthesize kinveyClient=_kinveyClient;
@synthesize ourImage = _ourImage;
@synthesize imageName = _imageName;
@synthesize imageState = _imageState;
@synthesize currentOperation = _currentOperation;
@synthesize rootViewController=_rootViewController;

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//
//    }
//    return self;
//}

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
    
    self.imageName.text = @"kinvey_image.png";
    
    
    //    [blob blobDelegate:self saveData:data  toBlob:@"kinvey_image.png"];
    
    
    //    [blob blobDelegate:self deleteBlog:@"kinvey_image.png"];

}


- (void)viewDidUnload
{
    [self setOurImage:nil];
    [self setImageName:nil];
    [self setImageState:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)resourceServiceDidCompleteWithResult:(KCSResourceResponse *)result
{
    NSLog(@"Request Completed with: %@", result);
    [result retain];
    if ([_currentOperation isEqualToString:@"GET"]){
        NSData *imageData = [result resource];
        _ourImage.image = [UIImage imageWithData:imageData];
        [self.ourImage setHidden:NO];
        self.imageState.text = @"Image from Kinvey";
    } else if ([_currentOperation isEqualToString:@"PUT"]) {
        self.imageState.text = @"Image sent to Kinvey!";
        [self refreshImage:self];
    } else {
        self.imageState.text = @"Image deleted from Kinvey";
        [self.ourImage setHidden:YES];
    }
    [result release];
}

- (void)resourceServiceDidFailWithError:(NSError *)error
{
    NSError *err = (NSError *)error;
    NSLog(@"BLOB Failed with error: %@ (%@)", err, [err userInfo]);
    NSString *errMsg = [NSString stringWithFormat:@"FAILED with error %d", [err code]];
    self.imageState.text = errMsg;
}


- (void)dealloc {
    [_ourImage release];
    [_imageName release];
    [_imageState release];
    [super dealloc];
}
- (IBAction)uploadImage:(id)sender {
    // Do File API here
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"metal_kinvey_1280x800" ofType:@"png"];  
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    
    _currentOperation = @"PUT";
    [KCSResourceService saveData:data toResource:self.imageName.text withDelegate:self];
}

- (IBAction)deleteImage:(id)sender {
    _currentOperation = @"DELETE";
    [KCSResourceService deleteResource:self.imageName.text withDelegate:self];
}

- (IBAction)refreshImage:(id)sender {
    _currentOperation = @"GET";
    [KCSResourceService downloadResource:self.imageName.text withResourceDelegate:self];
}

- (IBAction)flipView:(id)sender {
    return [self.rootViewController switchViews:sender];
}
@end
