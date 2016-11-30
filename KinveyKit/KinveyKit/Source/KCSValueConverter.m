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
                                                                                         options:0
                                                                                           error:nil];
            NSArray<NSTextCheckingResult*>* matches = [regex matchesInString:string
                                                                     options:0
                                                                       range:NSMakeRange(0, string.length)];
            if (matches.count > 0) {
                value = [KCSDateBuilder objectForJSONObject:string];
            }
        } else if (
            [mutableTypes containsObject:valueType] &&
            [value isKindOfClass:[NSObject class]] &&
            [value respondsToSelector:@selector(mutableCopy)] &&
            [value conformsToProtocol:@protocol(NSMutableCopying)]
        ) {
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
        if (value != [NSNull null]) {
            return value;
        } else if (valueType.length == 1) {
            switch ([valueType characterAtIndex:0]) {
                /*
                 Char codes according to Apple's documentation:
                 https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
                 */
                case 'c':
                    return [NSNumber numberWithChar:'\0'];
                case 'i':
                    return [NSNumber numberWithInt:0];
                case 's':
                    return [NSNumber numberWithShort:0];
                case 'l':
                    return [NSNumber numberWithLong:0];
                case 'q':
                    return [NSNumber numberWithLongLong:0];
                case 'C':
                    return [NSNumber numberWithUnsignedChar:0];
                case 'I':
                    return [NSNumber numberWithUnsignedInt:0];
                case 'S':
                    return [NSNumber numberWithUnsignedShort:0];
                case 'L':
                    return [NSNumber numberWithUnsignedLong:0];
                case 'Q':
                    return [NSNumber numberWithUnsignedLongLong:0];
                case 'f':
                    return [NSNumber numberWithFloat:0];
                case 'd':
                    return [NSNumber numberWithDouble:0];
                case 'B':
                    return [NSNumber numberWithBool:NO];
            }
        }
        return nil;
    }

@end
