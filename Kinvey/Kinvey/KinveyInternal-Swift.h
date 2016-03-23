//
//  KinveyInternal-Swift.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Kinvey/Kinvey-Swift.h>

@interface NSString ()

-(NSDate* _Nullable)toDate;

@end

@interface KNVRealmEntitySchema : NSObject

+(NSString* _Nullable)realmClassNameForClass:(Class _Nonnull)cls;

@end
