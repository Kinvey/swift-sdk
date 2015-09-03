//
//  KCSDataStoreOperationRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <KinveyKit/KinveyKit.h>
#import "DataStoreOperation.h"

@interface KCSDataStoreOperationRequest : KCSRequest

+(instancetype)requestWithDataStoreOperation:(DataStoreOperation*)dataStoreOperation;

-(instancetype)initWithDataStoreOperation:(DataStoreOperation*)dataStoreOperation;

@property (weak) DataStoreOperation* dataStoreOperation;
@property (weak, atomic) KCSRequest* request;

@end
