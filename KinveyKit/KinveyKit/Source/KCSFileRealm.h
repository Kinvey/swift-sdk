//
//  KCSFileRealm.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-11-25.
//  Copyright © 2015 Kinvey. All rights reserved.
//

#import <Realm/Realm.h>
#import "KCSMetadataRealm.h"

@interface KCSFileRealm : RLMObject

@property NSString* fileId;
@property NSString* filename;
@property long long length;
@property NSString* mimeType;
@property NSNumber<RLMInt>* publicFile;
@property KCSMetadataRealm* metadata;
@property NSString* localURL;
@property NSData* data;
@property NSString* remoteURL;
@property NSDate* expirationDate;
@property long long bytesWritten;
@property NSString* downloadURL;

@end
