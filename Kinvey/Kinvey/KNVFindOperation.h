//
//  KNVFindOperation.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVReadOperation.h"

@interface KNVFindOperation<T : NSObject<KNVPersistable>*> : KNVReadOperation<T, NSArray<T>*>

@end
