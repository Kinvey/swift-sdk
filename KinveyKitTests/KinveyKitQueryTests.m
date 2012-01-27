//
//  KinveyKitQueryTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitQueryTests.h"
#import "KCSQuery.h"
#import "NSString+KinveyAdditions.h"

@implementation KinveyKitQueryTests

// All code under test must be linked into the Unit Test bundle
- (void)testSomeQueries
{
    NSString *expectedJSON = @"{\"$or\":[{\"age\":{\"$gt\":30}},{\"jobs\":{\"$gt\":1,\"$lt\":5}}],\"children\":{\"$not\":{\"$lt\":3}}}";
    
    KCSQuery *query  = [KCSQuery queryOnField:@"age" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:30]];
    KCSQuery *query2 = [KCSQuery queryOnField:@"jobs" usingConditionalsForValues:
                        kKCSGreaterThan, [NSNumber numberWithInt:1],
                        kKCSLessThan, [NSNumber numberWithInt:5], nil];
    KCSQuery *orQuery = [KCSQuery queryForJoiningOperator:kKCSOr onQueries:query, query2, nil];
    
    [orQuery addQueryNegatingQuery:[KCSQuery queryOnField:@"children" usingConditional:kKCSLessThan forValue:[NSNumber numberWithInt:3]]];
    
    NSString *computedJSON = [orQuery JSONStringRepresentation];
    
    assertThat(computedJSON, is(equalTo(expectedJSON)));
    
    
    KCSQuery *geoQuery = [KCSQuery queryOnField:@"location" usingConditional:kKCSNearSphere forValue:[NSArray arrayWithObjects:[NSNumber numberWithFloat:50.0], [NSNumber numberWithFloat:50.0], nil]];
    
    NSLog(@"%@\n%@", [geoQuery JSONStringRepresentation], [NSString stringbyPercentEncodingString:[geoQuery JSONStringRepresentation]]);
}

@end
