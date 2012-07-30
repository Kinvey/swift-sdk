//
//  KCSResource.m
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSResource.h"

#import <UIKit/UIKit.h>

#define kTypeResourceValue @"resource"
#define kTypeKey @"_type"

#define kImageMimeType @"image/png"

@implementation KCSResource
@synthesize resource = _resource;
#pragma mark - Helpers

+ (BOOL) isResourceDictionary:(id)value
{
    return [value isKindOfClass:[NSDictionary class]] && [value valueForKey:@"_type"] != nil && [[value valueForKey:@"_type"] isEqualToString:kTypeResourceValue];
}

+ (id) resourceObjectFromData:(NSData*)data type:(NSString*)mimeType
{
    id resource = data;
    if ([mimeType isEqualToString:kImageMimeType]) {
        resource = [UIImage imageWithData:data];
    }
    return resource;
}

#pragma mark - 

- (id) initWithResource:(id)resource name:(NSString*)name
{
    self = [super init];
    if (self) {
        _blobName = [name retain];
        _resource = [resource retain];
    }
    return self;
}

- (id) initWithResource:(id)resource
{
    self = [super init];
    if (self) {
        _blobName = nil;
        _resource = [resource retain];
    }
    return self;
}

- (void) dealloc
{
    [_blobName release];
    [_resource release];
    [super dealloc];
}

NSString* mimeType(id obj);
NSString* mimeType(id obj)
{
    if ([obj isKindOfClass:[UIImage class]]) {
        return kImageMimeType;
    }
    return @"application/octet-stream";
}

- (NSDictionary*) dictionaryRepresentation
{
    NSDictionary* dictionary = [NSDictionary dictionaryWithObjectsAndKeys:kTypeResourceValue, kTypeKey, [self blobName], @"_loc", mimeType(_resource), @"_mime-type", nil];
    return dictionary;
}

- (NSData*) data
{
    NSData* data = nil;
    if ([_resource isKindOfClass:[NSURL class]]) {
        //URL toResource:[URL lastPathComponent]
        data = [NSData dataWithContentsOfURL:_resource];
    } else if ([_resource isKindOfClass:[NSString class]]) {
        data = [NSData dataWithContentsOfFile:_resource];
    } else if ([_resource isKindOfClass:[UIImage class]]) {
        data = UIImagePNGRepresentation(_resource);
    } //TODO: general
    return data;
}

- (void) setBlobName:(NSString *)blobName
{
    @synchronized(self) {
        [_blobName release];
        _blobName = [blobName retain];
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
            } else if ([_resource isKindOfClass:[UIImage class]]) {
                CFUUIDRef uuid = CFUUIDCreate(NULL);
                NSString *uuidString = nil;
                
                if (uuid){
                    uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
                    CFRelease(uuid);
                }
                
                location = [NSString stringWithFormat:@"%@.%@", uuidString, @"png"];
                [uuidString release];
            } //TODO: general
            _blobName = [location retain];
        }
    }
    return _blobName;
}


@end
