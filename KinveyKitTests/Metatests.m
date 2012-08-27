//
//  Metatests.m
//  KinveyKit
//
//  Created by Michael Katz on 7/31/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "Metatests.h"
#import <KinveyKit/KinveyKit.h>
#import "SBJson.h"

#import "TestUtils.h"

// RectangleHolder.h
@interface RectangleHolder : NSObject <KCSPersistable>
@property (nonatomic) CGRect rect;
@end
// RectangleHolder.m
@interface RectangleHolder ()
@property (nonatomic, assign) NSArray* rectArray;
@end
@implementation RectangleHolder
@synthesize rect;
- (NSDictionary *)hostToKinveyPropertyMapping {
    return @{ @"rectArray" : @"rect"};
}
- (void) setRectArray:(NSArray *)rectArray {
    self.rect = CGRectMake([[rectArray objectAtIndex:0] floatValue], //x
                           [[rectArray objectAtIndex:1] floatValue], //y
                           [[rectArray objectAtIndex:2] floatValue], //w
                           [[rectArray objectAtIndex:3] floatValue]); //h
}
- (NSArray*) rectArray {
    return @[@(self.rect.origin.x), @(self.rect.origin.y), @(self.rect.size.width), @(self.rect.size.height)];
}

@end


typedef struct {
    int x;
    int y;
} XXY;

@implementation Metatests
- (void) testX
{
    XXY ab;
    ab.x = 1;
    ab.y = 2;
    KCSCollection* c = [KCSCollection collectionFromString:@"COLLECTION" ofClass:[KCSEntityDict class]];
    NSLog(@"%@",c);
    
    NSAttributedString* e = [[NSAttributedString alloc] initWithString:@"A"];
    KCS_SBJsonWriter* s = [[KCS_SBJsonWriter alloc] init];
    NSData* d = [s dataWithObject:@[e]];
    NSLog(@"%@",d);
    
}

- (void) ntestE
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"should be setup");
    
    dispatch_queue_t myd = dispatch_queue_create("com.kinvey.testQ", NULL);
    self.done = NO;
    
//     dispatch_async(myd, ^{
//     NSLog(@"in q");
//     
//         [self runit2];
//     });

    NSOperationQueue* op = [[NSOperationQueue alloc] init];

    [op addOperationWithBlock:^{
        [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
            NSLog(@"in ping return");
            //    thisDone = YES;
            self.done = YES;
            //        dispatch_resume(<#dispatch_object_t object#>)
            //            dispatch_semaphore_signal(semi);
        }];
        [[NSRunLoop currentRunLoop] run];
    }];
    
    
//    NSThread* t =[[NSThread alloc] initWithTarget:self selector:@selector(startthread) object:nil];
//    [t start];
    [self poll];
    
}

- (void) runit2
{
    
    dispatch_semaphore_t semi = dispatch_semaphore_create(0);
  
    NSOperationQueue* op = [[NSOperationQueue alloc] init];
    
    [op addOperationWithBlock:^{
        [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
            NSLog(@"in ping return");
            //    thisDone = YES;
            self.done = YES;
            //        dispatch_resume(<#dispatch_object_t object#>)
//            dispatch_semaphore_signal(semi);
        }];
        [[NSRunLoop currentRunLoop] run];
    }];
    
  //  NSRunLoop* l = [NSRunLoop currentRunLoop];
   // [l runMode:@"ABC" beforeDate:[NSDate distantFuture]];
//    [q setMaxConcurrentOperationCount:1000];
  //  dispatch_source_create(<#dispatch_source_type_t type#>, <#uintptr_t handle#>, <#unsigned long mask#>, <#dispatch_queue_t queue#>)

//    dispatch_semaphore_wait(semi, DISPATCH_TIME_FOREVER);
    NSLog(@"done");
 //   dispatch_suspend(dispatch_get_current_queue());
}

- (void) runit
{
    NSRunLoop* runLoop = [NSRunLoop currentRunLoop];
    
    // Add the exitNow BOOL to the thread dictionary.
    //    NSMutableDictionary* threadDict = [[NSThread currentThread] threadDictionary];
    //    [threadDict setValue:[NSNumber numberWithBool:exitNow] forKey:@"ThreadShouldExitNow"];
    
    // Install an input source.
    // [self myInstallCustomInputSource];
    __block BOOL thisDone = NO;
    
    while (!thisDone)
    {
        // Do one chunk of a larger body of work here.
        // Change the value of the moreWorkToDo Boolean when done.
        [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
            NSLog(@"in ping return");
            thisDone = YES;
            
        }];
        
        
        // Run the run loop but timeout immediately if the input source isn't waiting to fire.
        [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:.1]];
        
        // Check to see if an input source handler changed the exitNow value.
        //  exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
    }
    self.done = YES;
}

- (void) startthread {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
//    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
//        NSLog(@"in ping return");
//        self.done = YES;
//        
//    }];
    
    [self runit];
    
    [pool release];
    
}
#if NEVER
- (void) predtests
{
    [NSPredicate predicateWithFormat:@"name LIKE %@", @"hamburger"];
    [KCSQuery queryOnField:@"name" withExactMatchForValue:@"hamburger"];
    [NSPredicate predicateWithFormat:@"(units LIKE cup) AND (quantity > 1)"];
    [[KCSQuery queryOnField:@"units" withExactMatchForValue:@"cup"] addQueryOnField:@"quantity" usingConditional:kKCSGreaterThan forValue:@1];
    
    NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Recipe"];
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    [req setSortDescriptors:@[sortDescriptor]];
    
    [NSPredicate predicateWithValue:YES];
    KCSQuery* query = [KCSQuery query]; //get everything query
    KCSQuerySortModifier* sort = [[KCSQuerySortModifier alloc] initWithField:@"name" inDirection:kKCSAscending];
    [query addSortModifier:sort];
    
  //  NSFetchRequest* req = [NSFetchRequest fetchRequestWithEntityName:@"Recipe"];
    req.fetchLimit = 40;
    req.fetchOffset = 40;

//    KCSQuery* query = [KCSQuery query];
    KCSQueryLimitModifier* limit = [[KCSQueryLimitModifier alloc] initWithLimit:40];
    KCSQuerySkipModifier* skip = [[KCSQuerySkipModifier alloc] initWithcount:40];
    [query setLimitModifer:limit];
    [query setSkipModifier:skip];
    
}
#endif
- (void) yy
{
    //    KCSCachedStore* store;
    //    [store group:@"team" reduce:[KCSReduceFunction AVERAGE:@"battingAverage"] condition:[KCSQuery queryOnField:@"age" usingConditional:kKCSGreaterThanOrEqual forValue:@30] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
    //        NSNumber* yankeesBattingAverage = [valuesOrNil reducedValueForFields:@{ @"team" : @"Yankees"}];
    //                                           NSLog(@"The batting average for all Yankees older than 30 is: %@", yankeesBattingAverage);
    //                                           } progressBlock:nil];
    KCSCollection* collection;
    int cachePolicy;
    //    [NSDictionary dictionaryWithObjectsAndKeys:collection, KCSStoreKeyResource, [NSNumber numberWithInt:cachePolicy], KCSStoreKeyCachePolicy, nil]
    //    NSDictionary* d = ;
    KCSCachedStore* store = [KCSCachedStore storeWithOptions:@{ KCSStoreKeyResource : collection, KCSStoreKeyCachePolicy : @((int)cachePolicy)}];
    
    [store group:@"team" reduce:[KCSReduceFunction AVERAGE:@"battingAverage"] completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        
        NSNumber* yankeesBattingAverage = [valuesOrNil reducedValueForFields:@{ @"team" : @"Yankees"}];
        NSLog(@"The most up-to-date batting average for all Yankees is: %@", yankeesBattingAverage);
    } progressBlock:nil cachePolicy:KCSCachePolicyNone];
    
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"fileCache"];
    
	[KCSResourceService saveLocalResource:[dataPath stringByAppendingPathComponent: @"mugshot.png"]
	                         withDelegate:self];
	
	[KCSResourceService saveLocalResource:[dataPath stringByAppendingPathComponent: @"Fabio.png"]
	                           toResource:@"myPhoto.png"
	                         withDelegate:self];
    
    
    NSDictionary *options2 = [NSDictionary dictionaryWithObjectsAndKeys:
                              @"YES",         KCS_PUSH_IS_ENABLED_KEY,
                              @"push key",    KCS_PUSH_KEY_KEY,
                              @"push secret", KCS_PUSH_SECRET_KEY,
                              KCS_PUSH_DEBUG, KCS_PUSH_MODE_KEY, nil];
    
    NSDictionary *options3 = @{ KCS_PUSH_IS_ENABLED_KEY : @"YES",  KCS_PUSH_KEY_KEY : @"<#PUSH KEY#>",
    KCS_PUSH_SECRET_KEY : @"<#PUSH SECRET#>",
    KCS_PUSH_MODE_KEY : KCS_PUSH_DEBUG};
    
    NSDictionary *options = @{ KCS_PUSH_IS_ENABLED_KEY : @"YES",
    KCS_PUSH_KEY_KEY : @"<#PUSH KEY#>",
    KCS_PUSH_SECRET_KEY : @"<#PUSH SECRET#>",
    KCS_PUSH_MODE_KEY : KCS_PUSH_DEBUG};
    
    NSArray* coordinates;
    coordinates = [NSArray  arrayWithObjects:
                   [NSNumber numberWithDouble:-71.083934],
                   [NSNumber numberWithDouble:42.362474], nil];
    coordinates = @[@-71.083934, @42.362474];
    
    //  [KCSCollection collectionFromString:@"ParentCollection" ofClass:[ParentClass class]]
}

- (void) neq
{
    KCSCollection* collection = [KCSCollection collectionFromString:@"<#collection name#>" ofClass:[NSObject class]];
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    [store loadObjectWithID:@"object1" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        dispatch_async(dispatch_queue_create("com.kinvey.lotsofwork", NULL), ^{
            [self doIntensiveWorkOn:objectsOrNil];
        });
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"percent complete = %f", percentComplete);
    }];
}


- (void) xys
{
  //  I'm having trouble getting past the first step of the setup. I'm trying to simply ping the service using the tutorial and I keep getting a "invalid credentials" response.
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid_eVWJLDiR0"
                                                 withAppSecret:@"e124b851ba7146628ce25d7b6d35910b"
                                                  usingOptions:nil];
  //  I checked them 100 times, seems right to me. Here's the pinging code, directly from the tutorial:
//    - (void)viewDidLoad{ [super viewDidLoad]; // Do any additional setup after loading the view, typically from a nib.
        // Ping Kinvey
        [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) { // This block gets executed when the ping completes
            NSString *title; if (result.pingWasSuccessful){ title = @"Kinvey Ping Success :)"; } else { title = @"Kinvey Ping Failed :("; }
            // Log the result
            NSLog(@"%@", result.description);
            // Display an alert stating the result
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title message: [result description] delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
            [alert show];
        }];
  //  }
    //    If you can assist in anyway it will be most helpful. Thanks,Frankie
    
}

@end
