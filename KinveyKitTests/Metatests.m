//
//  Metatests.m
//  KinveyKit
//
//  Created by Michael Katz on 7/31/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "Metatests.h"
#import <KinveyKit/KinveyKit.h>

#import "TestUtils.h"

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
}

- (void) testE
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

@end
