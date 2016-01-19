//
//  KCSURLRequestRealm.h
//  Kinvey
//
//  Created by Victor Barros on 2016-01-18.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

@interface KCSURLRequestRealm : RLMObject

@property NSString* requestId;

@property NSString* collectionName;
@property NSString* objectId;

@property NSString* method;
@property NSString* url;
@property NSData* headers;
@property NSData* body;

-(instancetype)initWithURLRequest:(NSURLRequest*)urlRequest
                   collectionName:(NSString*)collectionName
                         objectId:(NSString*)objectId;

@end
