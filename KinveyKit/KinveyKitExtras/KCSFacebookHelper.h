//
//  KCSFacebookHelper.h
//  KinveyKit
//
//  Created by Michael Katz on 3/22/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KCSFacebookOGAction @"action"
#define KCSFacebookOGObjectType @"object"
#define KCSFacebookOGEntityId @"entityId"

typedef void (^FacebookOGCompletionBlock)(NSString* actionId, NSError* errorOrNil);

@interface KCSFacebookHelper : NSObject

+ (NSDictionary*) parseDeepLink:(NSURL*)url;
+ (void) publishToOpenGraph:(NSString*)entityId action:(NSString*)action objectType:(NSString*)objectType optionalParams:(NSDictionary*)extraParams completion:(FacebookOGCompletionBlock)completionBlock;

@end
