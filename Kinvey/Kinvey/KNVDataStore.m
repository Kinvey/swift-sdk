//
//  KNVDataStore.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVDataStore.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KNVDataStore ()

@property (nonatomic, readwrite) KNVDataStoreType type;

@end

@implementation KNVDataStore

-(instancetype)initWithType:(KNVDataStoreType)type
                   forClass:(Class)clazz
{
    self = [super init];
    if (self) {
        self.type = type;
    }
    return self;
}

-(void)find:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    unsigned int classesCount;
    Class* classes = objc_copyClassList(&classesCount);
    Class class = nil;
    NSString* string = nil;
    for (unsigned int i = 0; i < classesCount; i++) {
        class = classes[i];
        string = NSStringFromClass(class);
        if ([string containsString:@"DataStore"]) {
            NSLog(@"%@", string);
        }
    }
    free(classes);
}

@end
