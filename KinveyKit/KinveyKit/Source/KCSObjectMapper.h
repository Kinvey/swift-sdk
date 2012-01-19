//
//  KCSObjectMapper.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/19/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSSerializedObject : NSObject
@property (nonatomic, readonly) BOOL isPostRequest;
@property (nonatomic, readonly) NSString *objectId;
@property (nonatomic, readonly) NSDictionary *dataToSerialize;

- (id)initWithObjectId:(NSString *)objectId dataToSerialize:(NSDictionary *)dataToSerialize isPostRequest:(BOOL)isPostRequest;
@end

@interface KCSObjectMapper : NSObject

+ (id)populateObject:(id)object withData: (NSDictionary *)data;
+ (id)makeObjectOfType:(Class)objectClass withData: (NSDictionary *)data;
+ (KCSSerializedObject *)makeKinveyDictionaryFromObject: (id)object;


@end
