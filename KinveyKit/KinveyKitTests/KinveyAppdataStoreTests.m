//
//  KinveyCollectionStoreTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyAppdataStoreTests.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"


@interface ASTTestClass : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *objId;
@property (nonatomic) int objCount;
@property (nonatomic, retain) NSString *objDescription;

@end

@implementation ASTTestClass

@synthesize objId = _objId;
@synthesize objCount = _objCount;
@synthesize objDescription = _objDescription;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = nil;
    
    if (map == nil){
        map = [NSDictionary dictionaryWithObjectsAndKeys:
               @"_id", @"objId",
               @"objCount", @"objCount",
               @"objDescription", @"objDescription", nil];
    }
    
    return map;
}

@end


@implementation KinveyAppdataStoreTests



-(void)testSaveOne
{
    ASTTestClass *obj = [[ASTTestClass alloc] init];
    
    
}

-(void)testSaveMany
{
    
}

- (void)testQuery
{
    
}

- (void)testQueryAll
{
    
}

- (void)testRemoveOne
{
    
}

- (void)testRemoveAll
{
    
}


- (void)testConfigure
{
    
}

- (void)testAuth
{
    
}


@end
