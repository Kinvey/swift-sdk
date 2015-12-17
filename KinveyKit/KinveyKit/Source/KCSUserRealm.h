//
//  KCSUser__RLMObject.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-11-24.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import <Realm/Realm.h>
#import "KCSMetadataRealm.h"

@interface KCSUserRealm : RLMObject

@property NSString* userId;
@property NSString* username;
@property KCSMetadataRealm* metadata;

//TODO offline query
//@property NSDictionary* push;

@end
