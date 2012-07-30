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

- (void)testStringsHaveNoBreaks
{
    NSString *expectedString = @"N0M5MUU2RTMtNDlFMy01RUNELUI2NjAtNUU5NDA0REVEMTUwOmIzOTI3MjM4LTViNTctNDQ5ZS1hMjdmLWZiNjM3ZDhhNWU4Yg==";
    NSString *string = @"7C91E6E3-49E3-5ECD-B660-5E9404DED150:b3927238-5b57-449e-a27f-fb637d8a5e8b";
    NSString *b64 = KCSbase64EncodedStringFromData([string dataUsingEncoding:NSUTF8StringEncoding]);
    assertThat(b64, is(expectedString));
    
    // Round trip
    NSData *bd64 = KCSdataFromBase64String(expectedString);
    NSString *actual = [[NSString alloc] initWithData:bd64 encoding:NSUTF8StringEncoding];
    assertThat(actual, is(equalTo(string)));
}

@end
