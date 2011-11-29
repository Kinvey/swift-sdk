//
//  KCSRESTRequest.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSRESTRequest.h"
#import "KCSConnectionPool.h"
#import "KCSClient.h"


@interface KCSRESTRequest()
@property (nonatomic, retain) NSMutableURLRequest *request;

- (id)initWithResource:(NSString *)resource usingMethod: (NSInteger)requestMethod;
@end

@implementation KCSRESTRequest

@synthesize resourceLocation=_resourceLocation;
@synthesize completionAction=_completionAction;
@synthesize failureAction=_failureAction;
@synthesize progressAction=_progressAction;
@synthesize headers=_headers;
@synthesize method=_method;
@synthesize isSyncRequest=_isSyncRequest;
@synthesize request=_request;

- (id)initWithResource:(NSString *)resource usingMethod: (NSInteger)requestMethod
{
    self = [super init];
    if (self){
        self.resourceLocation = resource; // I own this!
        _method = requestMethod;
        _completionAction = NULL;
        _progressAction = NULL;
        _failureAction = NULL;
        _isSyncRequest = NO;
        self.headers = [[NSMutableDictionary alloc] init];
        _request = nil;
    }
    return self;
}

- (void)dealloc
{
    [self.resourceLocation release];
    self.resourceLocation = nil;
    [self.headers release];
    self.headers = nil;
    
    self.request = nil;
    self.completionAction = NULL;
    self.progressAction = NULL;
    self.failureAction = NULL;
    
    [super dealloc];
}

+ (KCSRESTRequest *)requestForResource: (NSString *)resource usingMethod: (NSInteger)requestMethod
{
    return [[[KCSRESTRequest alloc] initWithResource:resource usingMethod:requestMethod] autorelease];
}

- (id)syncRequest
{
    self.isSyncRequest = YES;
    return self;
}

- (id)addHeaders: (NSDictionary *)theHeaders
{
    NSArray *keys = [theHeaders allKeys];
    
    // 
    for (NSString *key in keys) {
        [self.headers setValue:[theHeaders valueForKey:key] forKey:key];
    }
    
    return self;
}

- (id)addBody:(NSData *)theBody
{
    [self.request setHTTPBody:theBody];
    [self.request setValue:[NSString stringWithFormat:@"%d", [theBody length]] forHTTPHeaderField:@"Content-Length"];
    return self;
}

- (id)withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failure progressAction: (KCSConnectionProgressBlock)progress
{
    self.completionAction = complete;
    self.progressAction = progress;
    self.failureAction = failure;
    
    return self;
    
}

// Modify known headers
- (void)setContentType: (NSString *)contentType
{
    [self.headers setValue:contentType forKey:@"Content-Type"];
}

- (void)setContentLength: (NSInteger)contentLength
{
    [self.headers setValue:[NSNumber numberWithInt:contentLength] forKey:@"Content-Length"];    
}

// Prototype is to make compiler happy
- (NSString *)getHTTPMethodForConstant:(NSInteger)constant
{
    switch (constant) {
        case kGetRESTMethod:
            return @"GET";
            break;
        case kPutRESTMethod:
            return @"PUT";
            break;
        case kPostRESTMethod:
            return @"POST";
            break;
        case kDeleteRESTMethod:
            return @"DELETE";
            break;
            
        default:
            return @"";
            break;
    }
}


- (void)start
{
    KCSConnection *connection;
    
    if (self.isSyncRequest){
        connection = [[KCSConnectionPool syncConnection] retain];
    } else {
        connection = [[KCSConnectionPool asyncConnection] retain];
    }
    
//    self.request = [NSURLRequest requestWithURL:self.resourceLocation cachePolicy:XXX timeoutInterval:60.0];
    self.request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.resourceLocation]];
    [self.request  setHTTPMethod: [self getHTTPMethodForConstant: self.method]];
    
    for (NSString *key in [self.headers allKeys]) {
        [self.request addValue:[self.headers valueForKey:key] forHTTPHeaderField:key];
    }
    
    [self.request addValue:[[KCSClient sharedClient] userAgent] forHTTPHeaderField:@"User-Agent"];
    [self.request addValue:[NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSinceNow:0] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle] forHTTPHeaderField:@"Date"];
    [connection performRequest:self.request progressBlock:self.progressAction completionBlock:self.completionAction failureBlock:self.failureAction usingCredentials:[[KCSClient sharedClient] authCredentials]];
     
     [connection release];
}

@end
