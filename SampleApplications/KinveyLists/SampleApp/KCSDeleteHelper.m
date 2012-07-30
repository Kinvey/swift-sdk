//
//  KCSDeleteHelper.m
//  KinveyLists
//
//  Created by Brian Wilson on 12/8/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSDeleteHelper.h"
#import "KCSListEntry.h"

@interface KCSDeleteHelper()
@property (retain, nonatomic) KCSCollection *listItemsCollection;
@end

@implementation KCSDeleteHelper 

@synthesize listItemsCollection=_listItemsCollection;


- (id)init
{
    self = [super init];
    if (self){
        _listItemsCollection = [[[KCSClient sharedClient] collectionFromString:@"list-items" withClass:[KCSListEntry class]] retain];
    }
    return self;
}

- (void)dealloc
{
    [_listItemsCollection release];
    [super dealloc];
}

+ (id)deleteHelper
{
    KCSDeleteHelper *dh = [[[KCSDeleteHelper alloc] init] autorelease];
    return dh;
}

- (void)removeItemsFromList:(NSString *)list withListID:(NSString *)listID
{
    // We need the collection
    self.listItemsCollection.query = [KCSQuery queryOnField:@"list" withExactMatchForValue:listID];
    self.listItemsCollection.query.limitModifer = [[[KCSQueryLimitModifier alloc] initWithLimit:8] autorelease];
    [self.listItemsCollection fetchWithDelegate:self];
}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
    NSArray *itemsToDelete = (NSArray *)result;
    for (KCSListEntry *entry in itemsToDelete) {
        if (entry.hasCustomImage){
            [KCSResourceService deleteResource:entry.image withDelegate:self];
        }
        [entry deleteFromCollection:self.listItemsCollection withDelegate:self];
    }
}

- (void)resourceServiceDidCompleteWithResult:(KCSResourceResponse *)result
{
    NSLog(@"DH: Resource Delete worked: %@", result);
}

- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    NSLog(@"DH: Entity delete worked: %@", result);
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    NSLog(@"DH Fetch failed: %@", error);
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    NSLog(@"DH Persist Failed: %@", error);
}

- (void)resourceServiceDidFailWithError:(NSError *)error
{
    NSLog(@"DH Resource Failed: %@", error);
}

@end
