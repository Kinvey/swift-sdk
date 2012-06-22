//
//  PropertyUtil.m
//  KinveyKit
//
//  Created by Michael Katz on 6/4/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//


// PropertyUtil.m
#import "KCSPropertyUtil.h"
#import "objc/runtime.h"

@implementation KCSPropertyUtil

static const char * getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T' && attribute[1] != '@') {
            // it's a C primitive type:
            /* 
             if you want a list of what will be returned for these primitives, search online for
             "objective-c" "Property Attribute Description Examples"
             apple docs list plenty of examples of what you get for int "i", long "l", unsigned "I", struct, etc.            
             */
            return (const char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute) - 1] bytes];
        }        
        else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2) {
            // it's an ObjC id type:
            return "id";
        }
        else if (attribute[0] == 'T' && attribute[1] == '@') {
            // it's another ObjC object type:
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "";
}


+ (NSDictionary *)classPropsFor:(Class)klass
{    
    if (klass == NULL) {
        return nil;
    }
    
    NSMutableDictionary *results = [[[NSMutableDictionary alloc] init] autorelease];
    
    while (klass) {
        unsigned int outCount, i;
        objc_property_t *properties = class_copyPropertyList(klass, &outCount);
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            const char *propName = property_getName(property);
            if(propName) {
                const char *propType = getPropertyType(property);
                NSString *propertyName = [NSString stringWithUTF8String:propName];
                NSString *propertyType = [NSString stringWithUTF8String:propType];
                if (propertyType != nil && propertyName !=  nil) {
                    [results setObject:propertyType forKey:propertyName];
                }
            }
        }
        free(properties);
        klass = [klass superclass];
    }
    
    // returning a copy here to make sure the dictionary is immutable
    return [NSDictionary dictionaryWithDictionary:results];
}




@end