//
//  KCSResource.h
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSResource : NSObject {
    NSString* _blobName;
}

@property (nonatomic, retain) id resource;
@property (atomic, retain, getter = blobName) NSString* blobName;

- (id) initWithResource:(id)resource;
- (id) initWithResource:(id)resource name:(NSString*)name;

- (NSDictionary*) dictionaryRepresentation;
- (NSData*) data;

+ (BOOL) isResourceDictionary:(id)value;
+ (id) resourceObjectFromData:(NSData*)data type:(NSString*)mimeType;

@end
