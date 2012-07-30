//
//  KCSListEntry.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KinveyKit/KinveyKit.h>

@interface KCSListEntry : NSObject <KCSPersistable>
{
    // Kinvey Object ID
    NSString *_id;
}

@property (retain) NSString *name;
@property (retain) NSString *image;
@property (retain) UIImage *loadedImage;
@property (retain) NSString *itemDescription;
@property (retain) NSString *objectId;
@property (retain) NSString *list;
@property BOOL hasCustomImage;
@property BOOL imageStartedUpload;



- (id)init;
- (id)initWithName: (NSString *)name;
- (id)initWithName:(NSString *)name withDescription: (NSString *)description;

- (NSDictionary*)hostToKinveyPropertyMapping;



@end
