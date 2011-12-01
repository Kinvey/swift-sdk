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
@synthesize blobService = _blobService;
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
    _blobService = [[KCSBlobService alloc] init];
    [_blobService setKinveyClient:self.kinveyClient];
    
    
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

- (void)blobRequestDidComplete:(KCSBlobResponse *)result
{
    NSLog(@"Request Completed with: %@", result);
    
    if ([_currentOperation isEqualToString:@"GET"]){
        NSData *imageData = [result blob];
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
}

- (void)blobRequestDidFail:(id)error
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
    [_blobService blobDelegate:self saveData:data toBlob:self.imageName.text];

}

- (IBAction)deleteImage:(id)sender {
    _currentOperation = @"DELETE";
    [_blobService blobDelegate:self deleteBlob:self.imageName.text];
}

- (IBAction)refreshImage:(id)sender {
    _currentOperation = @"GET";
    [_blobService blobDelegate:self downloadBlob: self.imageName.text];

}

- (IBAction)flipView:(id)sender {
    return [self.rootViewController switchViews:sender];
}
@end
