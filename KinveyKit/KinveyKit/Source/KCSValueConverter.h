//
//  KCSValueConverter.h
//  KinveyKit
//
//  Created by Victor Hugo on 2016-09-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSValueConverter : NSObject

    +(id)convert:(id)value
       valueType:(NSString*)valueType;

@end
