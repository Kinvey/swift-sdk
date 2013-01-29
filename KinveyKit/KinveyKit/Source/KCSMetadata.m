//
//  KCSMetadata.m
//  KinveyKit
//
//  Created by Michael Katz on 6/25/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSMetadata.h"
#import "NSDate+ISO8601.h"
#import "KCSClient.h"
#import "KinveyUser.h"

#define kKMDLMTKey @"lmt"
#define kACLCreatorKey @"creator"
#define kACLReadersKey @"r"
#define kACLWritersKey @"w"
#define kACLGlobalReadKey @"gr"
#define kACLGlobalWriteKey @"gw"

NSString* KCSMetadataFieldCreator = @"_acl.creator";
NSString* KCSMetadataFieldLastModifiedTime = @"_kmd.lmt";

@interface KCSUser ()
- (NSString*) userId;
@end

@interface KCSMetadata ()
@property (nonatomic, retain, readonly) NSDate* lastModifiedTime;
@property (nonatomic, retain, readonly) NSMutableDictionary* acl;
@end

@implementation KCSMetadata

- (id) init
{
    self = [super init];
    if (self) {
        _acl = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id) initWithKMD:(NSDictionary*)kmd acl:(NSDictionary*)pACL
{
    self = [super init];
    if (self) {
        NSString* lmt = [kmd objectForKey:kKMDLMTKey];
        _lastModifiedTime = [NSDate dateFromISO8601EncodedString:lmt];
        _acl = [NSMutableDictionary dictionaryWithDictionary:pACL];

        NSMutableArray* readers = [_acl objectForKey:kACLReadersKey];
        if (readers != nil) {
            [_acl setObject:[readers mutableCopy] forKey:kACLReadersKey];
        }
        NSMutableArray* writers = [_acl objectForKey:kACLWritersKey];
        if (writers != nil) {
            [_acl setObject:[writers mutableCopy] forKey:kACLWritersKey];
        }
    }
    return self;
}

- (NSString*) creatorId 
{
    return [_acl objectForKey:kACLCreatorKey];
}

- (BOOL) hasWritePermission
{
    KCSUser* user = [[KCSClient sharedClient] currentUser];
    NSString* userId = [user userId];
    return [[self creatorId] isEqualToString:userId] || [[self usersWithWriteAccess] containsObject:userId] || [self isGloballyWritable];
}

#pragma mark - readers/writers

- (NSMutableArray *)readers
{
    NSMutableArray* readers = [_acl objectForKey:kACLReadersKey];
    if (readers == nil) {
        readers = [NSMutableArray array];
        [_acl setObject:readers forKey:kACLReadersKey];
    }
    DBAssert(readers != nil && [readers isKindOfClass:[NSMutableArray class]], @"should be mutable");
    return readers;
}

- (NSMutableArray *) writers
{
    NSMutableArray* writers = [_acl objectForKey:kACLWritersKey];
    if (writers == nil) {
        writers = [NSMutableArray array];
        [_acl setObject:writers forKey:kACLWritersKey];
    }
    DBAssert(writers != nil && [writers isKindOfClass:[NSMutableArray class]], @"should be mutable");
    return writers;
}

- (NSArray*) usersWithReadAccess
{
    return self.readers;
}

- (void) setUsersWithReadAccess:(NSArray*) readers
{
    [self.readers setArray:readers];
}

- (NSArray*) usersWithWriteAccess
{
    return self.writers;
}

- (void) setUsersWithWriteAccess:(NSArray*) writers
{
    [self.writers setArray:writers];
}

#pragma mark - Globals

- (BOOL) isGloballyReadable
{
    return [[_acl objectForKey:kACLGlobalReadKey] boolValue];
}

- (void) setGloballyReadable:(BOOL)readable
{
    [_acl setObject:@(readable) forKey:kACLGlobalReadKey];
}

- (BOOL) isGloballyWritable
{
    return [[_acl objectForKey:kACLGlobalWriteKey] boolValue];
}

- (void) setGloballyWritable:(BOOL)writable
{
    [_acl setObject:@(writable) forKey:kACLGlobalWriteKey];
}

- (NSDictionary*) aclValue
{
    return _acl;
}

@end
