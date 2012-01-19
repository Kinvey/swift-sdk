//
//  KinveyKitBase64Tests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/17/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitBase64Tests.h"
#import "KCSBase64.h"

@implementation KinveyKitBase64Tests

- (void)testBase64Enc
{
    NSString *expectedString = @"QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
    NSString *string = @"Aladdin:open sesame";
    NSString *b64 = KCSbase64EncodedStringFromData([string dataUsingEncoding:NSUTF8StringEncoding]);
    
    assertThat(b64, is(expectedString));
}

- (void)testBase64Dec
{
    NSString *string = @"QWxhZGRpbjpvcGVuIHNlc2FtZQ==";
    NSString *expectedString = @"Aladdin:open sesame";
    NSData *b64 = KCSdataFromBase64String(string);
    NSString *actual = [NSString stringWithUTF8String:[b64 bytes]];
    
    assertThat(actual, is(expectedString));    
}

@end
