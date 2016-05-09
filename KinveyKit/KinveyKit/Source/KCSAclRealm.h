//
//  KCSAclRealm.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-11-28.
//  Copyright © 2015 Kinvey. All rights reserved.
//

@import Realm;
#import "KCSStringRealm.h"

@interface KCSAclRealm : RLMObject

@property NSString* creator;
@property NSNumber<RLMBool>* gr;
@property NSNumber<RLMBool>* gw;
@property RLMArray<KCSStringRealm*><KCSStringRealm>* r;
@property RLMArray<KCSStringRealm*><KCSStringRealm>* w;

@end
