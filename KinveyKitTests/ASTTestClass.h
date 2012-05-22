//
//  ASTTestClass.h
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KinveyPersistable.h"

@interface ASTTestClass : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *objId;
@property (nonatomic) int objCount;
@property (nonatomic, retain) NSString *objDescription;

@end