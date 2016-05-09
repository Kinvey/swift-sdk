//
//  KCSStringRealm.h
//  Kinvey
//
//  Created by Victor Barros on 2016-05-09.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Realm/Realm.h>

@interface KCSStringRealm : RLMObject

@property NSString* stringValue;

@end

RLM_ARRAY_TYPE(KCSStringRealm)
