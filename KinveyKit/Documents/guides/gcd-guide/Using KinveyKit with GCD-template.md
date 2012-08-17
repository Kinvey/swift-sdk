## KinveyKit Grand Central Dispatch (GCD) Guide
We recommend that you call KinveyKit methods from the Main thread. KinveyKit uses `NSURLConnection` under the hood, which relies on run loops for asynchronous operation. This means any calls to the backend won't block the UI. When you call KinveyKit methods, the completionBlocks or delegate functions will be run on the main thread. If you have CPU-intensive code to run when a network operation completes, you should offload that using Grand Central Dispatch (GCD).

For example, this code is meant to be run on the main thread. The method `doSomethingMajorOn:` will be called on another thread to do heavy work on a background thread. This way everything stays in Apple's recommended strategy for networking. 

    - (void) callKinveyAndDoSomethingMajorAfter() 
    {
         KCSCollection* collection = [KCSCollection collectionFromString:@"<#collection name#>" ofClass:[CollectionClass class]];
         KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
        [store loadObjectWithID:@"object1" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            //offload intensive work to another dispatch queue using GCD
            dispatch_async(dispatch_queue_create("com.kinvey.lotsofwork", NULL), ^{
                [self doSomethingMajorOn:objectsOrNil];
            });
        } withProgressBlock:^(NSArray *objects, double percentComplete) {
            NSLog(@"percent complete = %f", percentComplete);
        }];
    }


## But I really want to do the networking callbacks on a background thread!
Okay, if you don't trust our library to be efficient on the main thread, or your code requires that you call the networking methods from another thread, you still can. The main gotcha when using `NSURLConnection` from a background thread is keeping the runloop alive long enough to complete the networking operation. Most of the time, you dispatch a block to a background thread, that block starts the url load, but because the callbacks are asynchronous, everything returns immediately and the thread is cleaned up, and then the callbacks are never called. 

For example, if you try this, it will fail:

    - (void) callKinveyAndFail() 
    {
         KCSCollection* collection = [KCSCollection collectionFromString:@"<#collection name#>" ofClass:[CollectionClass class]];
         KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
         dispatch_async(dispatch_queue_create("com.kinvey.lotsofwork", NULL), ^{
         	  //run loadObjectWithID: on a background thread
            [store loadObjectWithID:@"object1" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                //this is never called because the dispatch_queue is finished already
                [self doSomethingMajorOn:objectsOrNil];
            } withProgressBlock:^(NSArray *objects, double percentComplete) {
                NSLog(@"percent complete = %f", percentComplete);
            }];
          });
    }
    
The way around this is to set up your own operation queue on this background thread and keep it around so the network operation can complete. `NSOperationQueue` uses GCD under the hood, and thus it will run the `NSURLConnection` and its callbacks on yet another thread.

    - (void) callKinveyOnBackgroundThread() 
    {
         KCSCollection* collection = [KCSCollection collectionFromString:@"<#collection name#>" ofClass:[CollectionClass class]];
         KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
         NSOperationQueue* opQ = [[NSOperationQueue alloc] init];
        [opQ addOperationWithBlock:^{
         	  //No need for an additional dispatch_async! due to NSOperationQueue's behavior. 
         	  //loadObjectWithID: will be on a background thread
            [store loadObjectWithID:@"object1" withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                //this will be evaluated on the same thread as loadObjectWithID:
                [self doSomethingMajorOn:objectsOrNil];
            } withProgressBlock:^(NSArray *objects, double percentComplete) {
                NSLog(@"percent complete = %f", percentComplete);
            }];
          }];
    }

## Summary
It's best to use KinveyKit from  the main thread or in a `NSOperation`. Using `dispatch_async` to send KinveyKit calls to a background queue might clean up the operating context before callbacks can be fired.

## More Reference
The following WWDC videos cover networking and GCD best practices. An Apple iPhone Developer account is required to view them.

* [WWDC 2010 Video: Network Apps for iPhoneOS, Part 2](https://developer.apple.com/videos/wwdc/2010/?id=208)
* [WWDC 2010 Video: Introducing Blocks and Grand Central Dispatch on iPhone](https://developer.apple.com/videos/wwdc/2010/?id=206)
* [WWDC 2011 Video: Blocks and Grand Central Dispatch in Practice](https://developer.apple.com/videos/wwdc/2011/?id=308)
* [WWDC 2012 Video: Networking Best Practices](https://developer.apple.com/videos/wwdc/2012/?id=706)