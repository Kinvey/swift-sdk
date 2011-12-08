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
}

+ (id)deleteHelper
{
    KCSDeleteHelper *dh = [[[KCSDeleteHelper alloc] init] autorelease];
    return dh;
}

- (void)removeItemsFromList:(NSString *)list withListID:(NSString *)listID
{
    // We need the collection

    [self.listItemsCollection addFilterCriteriaForProperty:@"list" withStringValue:listID filteredByOperator:KCS_EQUALS_OPERATOR];
    [self.listItemsCollection collectionDelegateFetch:self];
}

- (void) fetchCollectionDidComplete: (NSObject *) result
{
    NSArray *itemsToDelete = (NSArray *)result;
    for (KCSListEntry *entry in itemsToDelete) {
        if (entry.hasCustomImage){
            [KCSResourceService deleteResource:entry.image withDelegate:self];
        }
        [entry deleteDelegate:self fromCollection:self.listItemsCollection];
    }
}

- (void)resourceServiceDidCompleteWithResult:(KCSResourceResponse *)result
{
    NSLog(@"DH: Resource Delete worked: %@", result);
}

- (void)persistDidComplete:(NSObject *)result
{
    NSLog(@"DH: Entity delete worked: %@", result);
}

- (void)fetchCollectionDidFail:(id)error
{
    NSLog(@"DH Fetch failed: %@", error);
}

- (void)persistDidFail:(id)error
{
    NSLog(@"DH Persist Failed: %@", error);
}

- (void)resourceServicetDidFailWithError:(NSError *)error
{
    NSLog(@"DH Resource Failed: %@", error);
}

@end
