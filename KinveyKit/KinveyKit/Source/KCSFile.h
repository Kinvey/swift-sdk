//
//  KCSResource.h
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KinveyPersistable.h"
#import "KCSMetadata.h"

/**
 This class is a wrapper for file store information.
 */
@interface KCSFile : NSObject <KCSPersistable>

///---
/// @name Basic Info
///---

/** The unique id of the file resource.
 */
@property (nonatomic, copy) NSString* fileId;

/** The file name (and extension) of the file. Does not have to be unique.
 */
@property (nonatomic, copy) NSString* filename;

/** The actual or expected size of the file.
 */
@property (nonatomic) NSUInteger length;

/** The file's type. 
 */
@property (nonatomic, copy) NSString* mimeType;

/** `YES` if the file is public on the Internet.
 */
@property (nonatomic, copy) NSNumber* public;

/** Control a resource's ACLs.
 */
@property (nonatomic, retain) KCSMetadata* metadata;

///----
/// @name Downloaded Data
///---


/** The URL to the file where the resource was saved to.
 
 Either only `localURL` or `data` will be valid for downloaded data.
 */
@property (nonatomic, retain, readonly) NSURL* localURL;

/** The downloaded data.
 
 Either only `localURL` or `data` will be valid for downloaded data.
 */

@property (nonatomic, retain, readonly) NSData* data;

@property (nonatomic, retain, readonly) id resolvedObject;

- (instancetype)initWithData:(NSData *)data fileId:(NSString*)fileId filename:(NSString*)filename mimeType:(NSString*)mimeType;
- (instancetype)initWithLocalFile:(NSURL *)localURL fileId:(NSString*)fileId filename:(NSString*)filename mimeType:(NSString*)mimeType;
///----
/// @name Streaming Data
///---

/** The location of the remote resource on it's actual server.
 */
@property (nonatomic, retain, readonly) NSURL* remoteURL;

/** The date until the `remoteURL` is good until. After that, the url must be re-fetched from Kinvey.
 */
@property (nonatomic, retain, readonly) NSDate* expirationDate;

#pragma mark - Linked Files API
//internal methods
+ (instancetype) fileRef:(id)objectToRef collectionIdProperty:(NSString*)idStr;
+ (instancetype) fileRefFromKinvey:(NSDictionary*)kinveyDict class:(Class)klass;
@end
