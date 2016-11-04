//
//  KCSValueConverter.m
//  KinveyKit
//
//  Created by Victor Hugo on 2016-09-21.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KCSValueConverter.h"
#import "KCSBuilders.h"

@implementation KCSValueConverter
    
    +(id)convert:(id)value
       valueType:(NSString*)valueType
    {
        /*
         Based on the basic classes:
         https://developer.apple.com/library/ios/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html
         */
        const NSSet* mutableTypes = [NSSet setWithArray:@[@"NSMutableArray",
                                                          @"NSMutableDictionary",
                                                          @"NSMutableSet",
                                                          @"NSMutableIndexSet",
                                                          @"NSMutableCharacterSet",
                                                          @"NSMutableData",
                                                          @"NSMutableString",
                                                          @"NSMutableAttributedString",
                                                          @"NSMutableURLRequest"]];
        if ([value isKindOfClass:[NSString class]]) {
            NSString* string = (NSString*) value;
            const NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(ISODate\\(\")?(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(.\\d{3})?Z)(\"\\))?"
                                                                                         options:nil
                                                                                           error:nil];
            NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:string
                                                                     options:nil
                                                                       range:NSMakeRange(0, string.length)];
            if (matches.count > 0) {
                value = [KCSDateBuilder objectForJSONObject:string];
            }
        } else if ([mutableTypes containsObject:valueType] &&
                   [value isKindOfClass:[NSObject class]] &&
                   [value respondsToSelector:@selector(mutableCopy)])
        {
            value = ((NSObject*) value).mutableCopy;
        }
        
        if ([value isKindOfClass:[NSMutableArray class]]) {
            NSMutableArray* array = (NSMutableArray*) value;
            NSMutableArray* results = [NSMutableArray arrayWithCapacity:array.count];
            for (id item in array) {
                [results addObject:[self convert:item
                                       valueType:valueType]];
            }
            value = results;
        } else if ([value isKindOfClass:[NSMutableDictionary class]]) {
            NSMutableDictionary* dict = (NSMutableDictionary*) value;
            NSMutableDictionary* results = [NSMutableDictionary dictionaryWithCapacity:dict.count];
            for (id key in dict) {
                results[key] = [self convert:dict[key]
                                   valueType:valueType];
            }
            value = results;
        }
        return value != [NSNull null] ? value : nil;
    }

@end
