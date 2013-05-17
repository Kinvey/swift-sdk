//
//  KCSEntityCache2.h
//  KinveyKit
//
//  Created by Michael Katz on 5/14/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSEntityCache.h"

@interface KCSEntityCache2 : NSObject <KCSEntityCache>
@property (nonatomic, strong) NSDictionary* saveContext;
@property (nonatomic, retain) NSString* persistenceId;

- (instancetype) initWithPersistenceId:(NSString*)key;


@end

