//
//  KinveyEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyEntity.h"

@implementation NSObject (KCSEntity)

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFetchOne: (NSString *)query
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value
{
    
}

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withCharValue: (char) value
{
    
}

- (NSString *)objectId{
    return nil;
}

- (NSString *)valueForKey: (NSString *)key
{
    return nil;
}

- (void)delagate: (id)delagate loadObjectWithId: (NSString *)objectId
{
    
}

//- (void)setValue: (NSString *)value forKey: (NSString *)key
//{
//    
//}


@end
