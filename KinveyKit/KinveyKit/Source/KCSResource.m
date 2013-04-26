//
//  KCSResource.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSResource.h"
#import "KCSImageUtils.h"

#define kTypeResourceValue @"resource"
#define kTypeKey @"_type"
#define kLocationKey @"_loc"
#define kMimeKey @"_mime-type"

#define kImageMimeType @"image/png"

@implementation KCSResource
#pragma mark - Helpers

+ (BOOL) isResourceDictionary:(id)value
{
    return [value isKindOfClass:[NSDictionary class]] && [value valueForKey:kTypeKey] != nil && [[value valueForKey:kTypeKey] isEqualToString:kTypeResourceValue];
}

+ (id) resourceObjectFromData:(NSData*)data type:(NSString*)mimeType
{
    id resource = data;
    if ([mimeType isEqualToString:kImageMimeType]) {
        resource = [KCSImageUtils imageWithData:data];
    }
    return resource;
}

#pragma mark - 

- (id) initWithResource:(id)resource name:(NSString*)name
{
    self = [super init];
    if (self) {
        _blobName = name;
        _resource = resource;
    }
    return self;
}

- (id) initWithResource:(id)resource
{
    self = [super init];
    if (self) {
        _blobName = nil;
        _resource = resource;
    }
    return self;
}

NSString* mimeType(id obj);
NSString* mimeType(id obj)
{
    if ([obj isKindOfClass:[ImageClass class]]) {
        return kImageMimeType;
    }
    return @"application/octet-stream";
}

- (id)proxyForJson
{
    return @{kTypeKey : kTypeResourceValue,
    kLocationKey : [self blobName],
    kMimeKey : mimeType(_resource)};
}

- (NSData*) data
{
    NSData* data = nil;
    if ([_resource isKindOfClass:[NSURL class]]) {
        //URL toResource:[URL lastPathComponent]
        data = [NSData dataWithContentsOfURL:_resource];
    } else if ([_resource isKindOfClass:[NSString class]]) {
        data = [NSData dataWithContentsOfFile:_resource];
    } else if ([_resource isKindOfClass:[ImageClass class]]) {
        data = [KCSImageUtils dataFromImage:_resource];
    } //TODO: general
    return data;
}

- (void) setBlobName:(NSString *)blobName
{
    @synchronized(self) {
        _blobName = blobName;
    }
}

- (NSString*) blobName
{
    @synchronized(self) {
        if (_blobName == nil) {
            NSString* location = nil;
            if ([_resource isKindOfClass:[NSURL class]]) {
                location = [_resource lastPathComponent];
            } else if ([_resource isKindOfClass:[NSString class]]) {
                location = [_resource lastPathComponent];
            } else if ([_resource isKindOfClass:[ImageClass class]]) {
                CFUUIDRef uuid = CFUUIDCreate(NULL);
                NSString *uuidString = nil;
                
                if (uuid){
                    uuidString = (NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
                    CFRelease(uuid);
                }
                
                location = [NSString stringWithFormat:@"%@.%@", uuidString, @"png"];
            } //TODO: general
            _blobName = location;
        }
    }
    return _blobName;
}

- (BOOL)isEqualDict:(NSDictionary*)dict
{
    return [[dict objectForKey:kTypeKey] isEqualToString:kTypeResourceValue] && [[dict objectForKey:kLocationKey] isEqualToString:[self blobName]] && [[dict objectForKey:kMimeKey] isEqualToString:mimeType(_resource)];
}

- (BOOL)isEqual:(id)obj
{
    if ([obj isKindOfClass:[KCSResource class]]) {
        return [self isEqualDict:[obj proxyForJson]];
    } else if ([obj isKindOfClass:[NSDictionary class]]) {
        return [self isEqualDict:obj];
    } else {
        return NO;
    }
}

@end
