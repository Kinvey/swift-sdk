//
//  TestThreads.m
//  KinveyKit
//
//  Created by Michael Katz on 7/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "TestThreads.h"
#import "KinveyKit.h"

#import "TestUtils.h"

@interface XYZ : NSOperation {
    BOOL executing;
    BOOL finished;
}

@end

@implementation XYZ

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    executing = NO;
    [self didChangeValueForKey:@"isExecuting"];
    [self main];
}

- (void)main
{
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
    NSURLConnection* cxn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [cxn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    
    //    [cxn setDelegateQueue:[NSOperationQueue mainQueue]];
    [cxn start];
   
    executing = YES;
    finished = NO;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return executing;
}

- (BOOL)isFinished
{
    return finished;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    NSLog(@"%@",data);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    //self.done = YES;
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    finished = YES;
    executing = NO;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    //self.done = YES;
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    finished = YES;
    executing = NO;
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];

}

@end

@implementation TestThreads

- (void) XtestDispatch
{
    bool status = [TestUtils setUpKinveyUnittestBackend];
    
    self.done = NO;
    __block NSRunLoop* loop;
//    [NSThread detachNewThreadSelector:@selector(runthis) toTarget:self withObject:nil];
    dispatch_queue_t myq = dispatch_queue_create("com.kinvey.testq", NULL);
    dispatch_retain(myq);
    dispatch_block_t block = ^(){
        [[NSAutoreleasePool alloc] init];
        loop = [[NSRunLoop currentRunLoop] retain];
        // Do this call to force getting a Kinvey generated username for the current user.
//        [NSOperationQueue 
        [KCSPing checkKinveyServiceStatusWithAction:^(KCSPingResult *result){
            NSLog(@"Kinvey ping performed. Success? %d. Result: %@", result.pingWasSuccessful, result.description);
            NSString *username = [[[KCSClient sharedClient] currentUser] username];
            
            // The local user is associated with the default context, which is associated with the main thread, so
            // we will dispatch to that before accessing and setting values on the local user object.
            dispatch_async(dispatch_get_main_queue(), ^{
                //            UWUser *localUser = self.dataStore.localUser;
                //            localUser.kinveyUsername = username;
                NSLog(@"kinveyUsername on local user is now: %@", username);
                self.done = YES;
            });
            while (1) {
            [[NSRunLoop currentRunLoop] run];
            }
        }];
        //[self poll];
    };
    [block retain];

    dispatch_async(myq, block);
    dispatch_retain(myq);
    [self poll];
}

- (void) runthis
{
    [[NSAutoreleasePool alloc] init];
//    dispatch_queue_t myq = dispatch_queue_create("com.kinvey.testq", NULL);
//    dispatch_retain(myq);
//    dispatch_async(myq, ^(){
        // Do this call to force getting a Kinvey generated username for the current user.
    NSOperationQueue* q = [[NSOperationQueue alloc] init];
    [q addOperationWithBlock:^{
        [KCSPing checkKinveyServiceStatusWithAction:^(KCSPingResult *result){
            NSLog(@"Kinvey ping performed. Success? %d. Result: %@", result.pingWasSuccessful, result.description);
            NSString *username = [[[KCSClient sharedClient] currentUser] username];
            
            // The local user is associated with the default context, which is associated with the main thread, so
            // we will dispatch to that before accessing and setting values on the local user object.
            dispatch_async(dispatch_get_main_queue(), ^{
                //            UWUser *localUser = self.dataStore.localUser;
                //            localUser.kinveyUsername = username;
                NSLog(@"kinveyUsername on local user is now: %@", username);
                self.done = YES;
            });
        }];
    }];
//    });

}

- (void) testY
{
    XYZ* xyz = [[XYZ alloc] init];
    self.done = NO;
    dispatch_queue_t myq =
    dispatch_get_main_queue();
    //dispatch_queue_create("com.kinvey.testq", NULL);
    dispatch_async(myq, ^{
        NSOperationQueue* q = 
        [NSOperationQueue currentQueue];
        //[[NSOperationQueue alloc] init];
        [q addOperation:xyz];
        NSUInteger c = [q operationCount];
//        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.yahoo.com"]];
//        NSURLConnection* cxn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//        [cxn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//        
//        //    [cxn setDelegateQueue:[NSOperationQueue mainQueue]];
//        [cxn start];
//        //        [[NSOperationQueue currentQueue] addOperation:cxn];
//        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:100]];
//        while (1) {
//            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:10]];
//        }
        NSLog(@"-");
        
    });
    [self poll];
}

- (void) __testX
{
    self.done = NO;
    dispatch_queue_t myq = dispatch_queue_create("com.kinvey.testq", NULL);
    dispatch_async(myq, ^{
        NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.yahoo.com"]];
        NSURLConnection* cxn = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        [cxn scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
    //    [cxn setDelegateQueue:[NSOperationQueue mainQueue]];
        [cxn start];
//        [[NSOperationQueue currentQueue] addOperation:cxn];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:100]];
    });
    [self poll];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"%@",data);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.done = YES;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.done = YES;
}

@end
