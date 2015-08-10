//
//  KCSMutableSortedDictionary.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-22.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSMutableOrderedDictionary : NSMutableDictionary

+(instancetype)dictionaryWithDictionary:(NSDictionary *)dict
                          andIgnoreKeys:(NSArray *)ignoreKeys;

-(instancetype)initWithDictionary:(NSDictionary *)otherDictionary;

-(instancetype)initWithDictionary:(NSDictionary *)otherDictionary
                    andIgnoreKeys:(NSArray *)ignoreKeys;

@end
