//
//  KCSDeleteHelper.h
//  KinveyLists
//
//  Created by Brian Wilson on 12/8/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KinveyKit/KinveyKit.h>

@interface KCSDeleteHelper : NSObject <KCSPersistableDelegate, KCSResourceDelegate, KCSCollectionDelegate>

+ (id)deleteHelper;
- (void)removeItemsFromList: (NSString *)list withListID: (NSString *)listID; 

@end
