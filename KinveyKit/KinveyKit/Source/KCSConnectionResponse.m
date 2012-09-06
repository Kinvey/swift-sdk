//
//  KCSConnectionResponse.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KCSConnectionResponse.h"
#import "KCS_SBJsonParser.h"
#import "KCSLogManager.h"
#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "NSString+KinveyAdditions.h"

@implementation KCSConnectionResponse

@synthesize responseCode=_responseCode;
@synthesize responseData=_responseData;
@synthesize userData=_userData;
@synthesize responseHeaders=_responseHeaders;

- (id)initWithCode:(NSInteger)code responseData:(NSData *)data headerData:(NSDictionary *)header userData:(NSDictionary *)userDefinedData
{
    self = [super init];
    if (self){
        _responseCode = code;
        _responseData = [data retain];
        _userData = [userDefinedData retain];
        _responseHeaders = [header retain];
    }
    
    return self;
}

+ (KCSConnectionResponse *)connectionResponseWithCode:(NSInteger)code responseData:(NSData *)data headerData:(NSDictionary *)header userData:(NSDictionary *)userDefinedData
{
    // Return the autoreleased instance.
    if (code < 0){
        code = -1;
    }
    return [[[KCSConnectionResponse alloc] initWithCode:code responseData:data headerData:header userData:userDefinedData] autorelease];
}

- (void)dealloc
{
    [_responseData release];
    [_userData release];
    [_responseHeaders release];
    [super dealloc];
}


- (NSString*) stringValue
{
    return [[[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding] autorelease];
}

- (id) jsonResponseValue:(NSError**) anError format:(NSStringEncoding)format
{
    KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
    NSString* string = [[NSString alloc] initWithData:self.responseData encoding:format];
    NSDictionary *jsonResponse = [parser objectWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [string release];
    if (parser.error) {
        KCSLogError(@"JSON Serialization retry failed: %@", parser.error);
        if (anError != NULL) {
            *anError = [KCSErrorUtilities createError:nil description:parser.error errorCode:KCSInvalidJSONFormatError domain:KCSNetworkErrorDomain];
        }
    }
    [parser release];
    NSObject *jsonData = [jsonResponse valueForKey:@"result"];
    return jsonData;
}

- (id) jsonResponseValue:(NSError**) anError
{
    //results are now wrapped by request in KCSRESTRequest, and need to unpack them here.
    KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
    NSDictionary *jsonResponse = [parser objectWithData:self.responseData];
    NSObject *jsonData = nil;
    if (parser.error) {
        KCSLogError(@"JSON Serialization failed: %@", parser.error);
        if ([parser.error isEqualToString:@"Broken Unicode encoding"]) {
            NSObject* reevaluatedObject = [self jsonResponseValue:anError format:NSASCIIStringEncoding];
            [parser release];
            return reevaluatedObject;
        } else {
            if (anError != NULL) {
                *anError = [KCSErrorUtilities createError:nil description:parser.error errorCode:KCSInvalidJSONFormatError domain:KCSNetworkErrorDomain];
            }
        }
    } else {
        jsonData = [jsonResponse valueForKey:@"result"];
        jsonData = jsonData ? jsonData : jsonResponse;
    }
    [parser release];
    
    return jsonData;
}

- (id) jsonResponseValue
{
    NSString* cytpe = [_responseHeaders valueForKey:@"Content-Type"];
    
    if (cytpe == nil || [cytpe containsStringCaseInsensitive:@"json"]) {
        return [self jsonResponseValue:nil];
    } else {
        if (_responseData.length == 0) {
            return @{};
        } else {
            KCSLogWarning(@"not a json repsonse");
            return @{@"debug" : [self stringValue]};
        }
    }
}

@end
