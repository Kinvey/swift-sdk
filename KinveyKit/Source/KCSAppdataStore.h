//
//  KCSAppdataStore.h
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSStore.h"

@interface KCSAppdataStore : NSObject <KCSStore>

@property (nonatomic, retain) KCSAuthHandler *authHandler;

@end
