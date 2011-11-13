//
//  KinveyCollection.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyCollection.h"
#import "KinveyEntity.h"
#import "NSString+KinveyAdditions.h"
#import "JSONKit.h"

////////// PRIVATE HELPER CLASSES

// Mapping from CollectionDelegate to ActionDelegate
@interface KCSCollectionDelegateMapper : NSObject <KCSClientActionDelegate>

@property (retain) id<KCSCollectionDelegate> mappedDelegate; // delegate
@property (retain) JSONDecoder *jsonDecoder;                 // Persistent decoder
@property (retain) KCSCollection *resultStore;
@property (retain) NSObject *objectTemplate;
@property (retain) NSString *collection;

- (id)initWithDelegate: (id<KCSCollectionDelegate>) delegate;
- (void) actionDidFail: (id)error;
- (void) actionDidComplete: (NSObject *) result;

@end

// Implementation
@implementation KCSCollectionDelegateMapper

@synthesize mappedDelegate=_mappedDelegate;
@synthesize jsonDecoder=_jsonDecoder;
@synthesize resultStore=_resultStore;
@synthesize objectTemplate=_objectTemplate;
@synthesize collection=_collection;

- (id)init
{
    return [self initWithDelegate:nil];
}
- (id)initWithDelegate:(id<KCSCollectionDelegate>)delegate
{    
    self = [super init];
    
    if (self){
        [self setJsonDecoder: [[JSONDecoder alloc] init]];
        [self setMappedDelegate:delegate];
        [self setResultStore:nil];
    }
    return self;
}

- (void) actionDidFail: (id)error
{
    NSLog(@"Action Failed! %@", error);
    [[self mappedDelegate] fetchCollectionDidFail:error];
}

- (void) actionDidComplete: (NSObject *) result
{
    NSLog(@"Fetch request did succeed");
//    NSArray *jsonData = [[self jsonDecoder] objectWithData:(NSData *)result];
    NSDictionary *hostToJsonMap = [[self objectTemplate] hostToKinveyPropertyMapping];
    NSMutableArray *processedData = [[NSMutableArray alloc] init];
    
    Class templateClass = [[self objectTemplate] class];
    
    NSObject *jsonData = [[self jsonDecoder] objectWithData:(NSData *)result];
    NSArray *jsonArray;
    

    if ([jsonData isKindOfClass:[NSArray class]]){
        jsonArray = (NSArray *)jsonData;
    } else {
        jsonArray = [[NSArray alloc] initWithObjects:(NSDictionary *)jsonData, nil];
    }
    
    for (NSDictionary *dict in jsonArray) {
 
        id copiedObject = [[templateClass alloc] init];
        
        for (NSString *hostKey in hostToJsonMap) {
            NSString *jsonKey = [hostToJsonMap objectForKey:hostKey];

//            NSLog(@"Mapping from %@ to %@ (using value: %@)", jsonKey, hostKey, [dict valueForKey:jsonKey]);

            [copiedObject setValue:[dict valueForKey:jsonKey] forKey:hostKey];
//            NSLog(@"Copied Object: %@", copiedObject);
        }
        [copiedObject setEntityCollection:[self collection]];
        [processedData addObject:copiedObject];
    }
    
    // result should now be the correct type
    if ([self resultStore]){
        [[self resultStore] setLastFetchResults:processedData];
    }
    
    [[self mappedDelegate] fetchCollectionDidComplete:processedData];
}

@end

// Mapping from CollectionDelegate to ActionDelegate
@interface KCSInformationDelegateMapper : NSObject <KCSClientActionDelegate>

@property (retain) id<KCSInformationDelegate> mappedDelegate; // delegate
@property (retain) JSONDecoder *jsonDecoder;                 // Persistent decoder

- (id) initWithDelegate: (id<KCSInformationDelegate>)delegate;
- (void) actionDidFail: (id)error;
- (void) actionDidComplete: (NSObject *) result;

@end

// Implementation
@implementation KCSInformationDelegateMapper

@synthesize mappedDelegate=_mappedDelegate;
@synthesize jsonDecoder=_jsonDecoder;

- (id) initWithDelegate: (id<KCSInformationDelegate>)delegate;
{    self = [super init];
    
    if (self){
        self.jsonDecoder = [[JSONDecoder alloc] init];
        [self setMappedDelegate:delegate];
    }
    return self;
}

- (void)dealloc
{
    [[self jsonDecoder] release];
}

- (void) actionDidFail: (id)error
{
    NSLog(@"Action Failed!");
}
- (void) actionDidComplete: (NSObject *) result
{
    NSDictionary *jsonData = [self.jsonDecoder objectWithData:(NSData *)result];
    int count;
    NSString *val = [jsonData valueForKey:@"count"];
    
    if (val){
        count = [val intValue];
    } else {
        count = 0;
    }

    [[self mappedDelegate] informationOperationDidComplete:count];
    

}
@end



@interface KCSCollection ()
@property (retain) JSONDecoder *decoderHelper;
@end




@implementation KCSCollection

// Usage concept
// In controller
// self.objectCollection = [[KCSCollection alloc] init];
// self.objectCollection.collectionName = @"lists";
// self.objectColleciton.objectTemplate = [[MyObject alloc] init];
// self.objectCollection.kinveyConnection = [globalConnection];
//
// And later...
// [self.objectCollection collectionDelegateFetchAll: ()

@synthesize collectionName=_collectionName;
@synthesize kinveyClient=_kinveyClient;
@synthesize objectTemplate=_objectTemplate;
@synthesize lastFetchResults=_lastFetchResults;
@synthesize decoderHelper=_decoderHelper;
@synthesize filters=_filters;

// TODO: Need a way to store the query portion of the library.
- (id)init
{
    self = [super init];
    if (self){
        [self setCollectionName:nil];
        [self setKinveyClient:nil];
        [self setObjectTemplate:nil];
        [self setLastFetchResults:nil];
        [self setDecoderHelper:[[JSONDecoder alloc] init]];
        [[self decoderHelper] retain];
        
        [self setFilters:[[NSMutableArray alloc] init]];
    }
    return self;
}

- (void)dealloc
{
    [[self decoderHelper] release];
}

#pragma mark Basic Methods

- (void)collectionDelegateFetchAll: (id <KCSCollectionDelegate>)delegate
{

    // Format the request and dispatch it...
    KCSCollectionDelegateMapper *mapper = [[KCSCollectionDelegateMapper alloc] initWithDelegate:delegate];
    [mapper setObjectTemplate:[self objectTemplate]];
    [mapper setCollection:[self collectionName]];
    [[self kinveyClient] clientActionDelegate:mapper forGetRequestAtPath: [self collectionName]];
    
}

// Private class helper method...
+ (NSString *)getOperatorString: (int)op
{
    switch (op) {
        case KCS_EQUALS_OPERATOR:
            return nil;
            break;
        case KCS_LESS_THAN_OPERATOR:
            return @"$lt";
            break;
        case KCS_GREATER_THAN_OPERATOR:
            return @"$gt";
            break;
        case KCS_LESS_THAN_OR_EQUAL_OPERATOR:
            return @"$lte";
            break;
        case KCS_GREATER_THAN_OR_EQUAL_OPERATOR:
            return @"$gte";
            break;
            
        default:
            return nil;
            break;
    }
}

- (NSString *)buildQueryForProperty: (NSString *)property withValue: (id)value filteredByOperator: (int)op
{
    NSString *query;
    
    NSString *stringValue;
    
    // Check to see if the object is a string or a real object
    // surround strings with quotes, values without
    if ([value isKindOfClass:[NSString class]]){
        stringValue = [NSString stringWithFormat:@"\"%@\"", value];
    } else {
        stringValue = [NSString stringWithFormat:@"%@", value];
    }
    
    if (op == KCS_EQUALS_OPERATOR){
        query = [NSString stringWithFormat:@"\"%@\": %@", property, stringValue];
    } else {
        query = [NSString stringWithFormat:@"\"%@\": {\"%@\": %@}", property, [KCSCollection getOperatorString:op], stringValue];
    }
    [query autorelease];
    return query;
    
}

- (NSString *)buildQueryForFilters: (NSArray *)filters
{
    NSString *outputString = @"{";
    for (NSString *filter in filters) {
        outputString = [outputString stringByAppendingFormat:@"%@, ", filter];
    }
    
    // String the trailing ','
    if ([outputString characterAtIndex:[outputString length]-2] == ','){
        outputString = [outputString substringToIndex:[outputString length] -2];
    }
    
    return [outputString stringByAppendingString:@"}"];
}


#pragma mark Query Methods
- (void)addFilterCriteriaForProperty: (NSString *)property withBoolValue: (BOOL) value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
}

- (void)addFilterCriteriaForProperty: (NSString *)property withDoubleValue: (double)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
	
}

- (void)addFilterCriteriaForProperty: (NSString *)property withIntegerValue: (int)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:[NSNumber numberWithBool:value] filteredByOperator:operator]];
	
}

- (void)addFilterCriteriaForProperty: (NSString *)property withStringValue: (NSString *)value filteredByOperator: (int)operator
{
    [[self filters] addObject:[self buildQueryForProperty:property withValue:value filteredByOperator:operator]];
	
}

- (void)collectionDelegateFetch: (id <KCSCollectionDelegate>)delegate
{
    KCSCollectionDelegateMapper *mapper = [[KCSCollectionDelegateMapper alloc] initWithDelegate:delegate];
    [mapper setObjectTemplate:[self objectTemplate]];

    [[self kinveyClient] clientActionDelegate:mapper forGetRequestAtPath: [[self collectionName] stringByAppendingFormat:@"/?query=%@", 
                                                                           [NSString stringbyPercentEncodingString:
                                                                            [self buildQueryForFilters:[self filters]]]]];

}

#pragma mark Utility Methods

- (void)informationDelegateCollectionCount: (id <KCSInformationDelegate>)delegate
{
	
    KCSInformationDelegateMapper *mapper = [[KCSInformationDelegateMapper alloc] initWithDelegate:delegate];
    
    [[self kinveyClient] clientActionDelegate:mapper forGetRequestAtPath: [NSString stringWithFormat:@"%@/%@", [self collectionName], @"_count"]];
    [mapper release];
}

// AVG is not in the REST docs anymore


@end
