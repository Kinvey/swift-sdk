//
//  KCSAuthCredential.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/17/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSAuthCredential.h"
#import "KCSRESTRequest.h"
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KCSLogManager.h"
#import "KCSBase64.h"

enum {
    KCSAuthNoAuth = 0,
    KCSAuthBasicAuthAppKey = 1,
    KCSAuthBasicAuthUser = 2
};

NSInteger deriveAuth(NSString *URL, NSInteger method);
NSInteger deriveAuth(NSString *URL, NSInteger method)
{
    // Default to none
    NSInteger authType = KCSAuthNoAuth;
    KCSClient *client = [KCSClient sharedClient];
    
    if ([URL hasPrefix:client.appdataBaseURL]){
        authType = KCSAuthBasicAuthUser;
    } else if ([URL hasPrefix:client.resourceBaseURL]){
        authType = KCSAuthBasicAuthUser;
    } else if ([URL hasPrefix:client.userBaseURL]){
        // We need auth, but we're not sure what type yet
        // Per the user API if we're POSTING to the ROOT of the user API,
        // then we need App Key auth, otherwise we need user auth
        if (method == kPostRESTMethod && [URL isEqualToString:client.userBaseURL]){
            authType = KCSAuthBasicAuthAppKey;
        } else {
            authType = KCSAuthBasicAuthUser;
        }
    } else {
        // No auth known, this needs to be extensable in the future to add new methods
        authType = KCSAuthNoAuth;
    }
    
    
    return authType;
}

@interface KCSAuthCredential ()
@property (nonatomic) NSInteger authRequired;
@property (nonatomic, retain) NSURLCredential *appKeyAuth;
@property (nonatomic, retain) NSString *appKeyBase64;
@end

@implementation KCSAuthCredential

@synthesize URL = _URL;
@synthesize method = _method;
@synthesize authRequired = _authRequired;
@synthesize appKeyAuth = _appKeyAuth;
@synthesize appKeyBase64 = _appKeyBase64;

- (id)initWithURL: (NSString *)URL withMethod: (NSInteger)method
{
    self = [super init];
    if (self){
        _URL = [URL retain];
        _method = method;
        _authRequired = deriveAuth(_URL, _method);
        _appKeyAuth = [NSURLCredential credentialWithUser:[[KCSClient sharedClient] appKey] password:[[KCSClient sharedClient] appSecret] persistence:NSURLCredentialPersistenceNone];
        _appKeyBase64 = [KCSbase64EncodedStringFromData([[NSString stringWithFormat:@"%@:%@", [[KCSClient sharedClient] appKey], [[KCSClient sharedClient] appSecret]] dataUsingEncoding:NSUTF8StringEncoding]) retain];
    }
    return self;
}

+ (KCSAuthCredential *)credentialForURL: (NSString *)URL usingMethod: (NSInteger)method
{
    return [[[KCSAuthCredential alloc] initWithURL:URL withMethod:method] autorelease];
}

- (NSURLCredential *)NSURLCredential
{
    if (self.authRequired == KCSAuthNoAuth){
        return nil;
    } else if (self.authRequired == KCSAuthBasicAuthAppKey){
        return self.appKeyAuth;
    } else if (self.authRequired == KCSAuthBasicAuthUser){
        KCSUser *curUser = [[KCSClient sharedClient] currentUser];
        if (curUser == nil){
            // We need to start auth proceeding here
            if (![[KCSClient sharedClient] userAuthenticationInProgress]){
                // We're the first!
                [KCSUser initCurrentUser];
            }
            return nil;
        } else {
            return [NSURLCredential credentialWithUser:curUser.username password:curUser.password persistence:NSURLCredentialPersistenceNone];
        }
    }
    
    KCSLogError(@"The type of auth required for this request (in NSURLCredential) is not known: %d", self.authRequired);
    return nil;
}


- (NSString *)HTTPBasicAuthString
{
    if (self.authRequired == KCSAuthNoAuth){
        return nil;
    } else if (self.authRequired == KCSAuthBasicAuthAppKey){
        return [NSString stringWithFormat:@"Basic %@", self.appKeyBase64];
    } else if (self.authRequired == KCSAuthBasicAuthUser){
        KCSUser *curUser = [[KCSClient sharedClient] currentUser];
        if (curUser == nil){
            // We need to start auth proceeding here
            if (![[KCSClient sharedClient] userAuthenticationInProgress]){
                // We're the first!
                [KCSUser initCurrentUser];
            }
            return nil;
        } else {
            return [NSString stringWithFormat:@"Basic %@", KCSbase64EncodedStringFromData([[NSString stringWithFormat:@"%@:%@", curUser.username, curUser.password] dataUsingEncoding:NSUTF8StringEncoding])];
        }
    }
    
    KCSLogError(@"The type of auth required for this request (in NSURLCredential) is not known: %d", self.authRequired);
    return nil;
}

- (BOOL)requiresAuthentication
{
    if (self.authRequired == KCSAuthNoAuth){
        return NO;
    } else {
        return YES;
    }
}

@end
