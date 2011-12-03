//
//  KinveyUser.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyUser.h"
#import "KCSClient.h"
#import "KCSKeyChain.h"
#import "KCSRESTRequest.h"
#import "KinveyAnalytics.h"
#import "JSONKit.h"
#import "KinveyBlocks.h"
#import "KCSConnection.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"


@interface KCSUser()
@property (nonatomic, retain) NSString *userId;
@end

@implementation KCSUser

@synthesize username=_username;
@synthesize password=_password;
@synthesize userId=_userId;


- (void)dealloc
{
    [_username release];
    [_password release];
    [_userId release];
    [super dealloc];
}

- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request
{
    BOOL localInitInProgress = NO;
    KCSClient *client = [KCSClient sharedClient];

    @synchronized(client){
        if (client.userAuthenticationInProgress == NO){
            client.userAuthenticationInProgress = YES;
            localInitInProgress = YES;
        }
    }
    
    // Note!!! This is a spin lock!  If we hold the lock for 5 seconds we're hosed, so this timeout
    // is REALLY big, hopefully we only hit it when the network is down (likely a minute timeout, so these guys will start timing out early...)
    NSDate *timeoutTime = [NSDate dateWithTimeIntervalSinceNow:5];

    if (!localInitInProgress && !client.userIsAuthenticated){
        while (!client.userIsAuthenticated) {
            NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
            // From NSDate documentation:
            //      The receiver and anotherDate are exactly equal to each other, NSOrderedSame
            //      The receiver is later in time than anotherDate, NSOrderedDescending
            //      The receiver is earlier in time than anotherDate, NSOrderedAscending.
            // So we're checking to see if now (the receiver) is later than timeoutTime (anotherDate), so we use NSOrderedDescending.

            if ([now compare:timeoutTime] == NSOrderedDescending){
                // TIMEOUT!  Give up!
                // We're not in a critical section and we don't have anything locked, so do some work before we quit.
                NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Network Timeout", @"failure", @"User Auth timeout", @"Kinvey Internal Error", nil];
                if (request != nil){
                    // We're going to Make a failure happen here...
                    request.failureAction([NSError errorWithDomain:@"KINVEY ERROR" code:-1 userInfo:errorDict]);
                } else {
                    // This case is not handled yet...
                    NSException* myException = [NSException
                                                exceptionWithName:@"KinveyInternalError"
                                                reason:@"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo"
                                                userInfo:errorDict];
                    
                    @throw myException;
                }
                break;
            }
        }
    }
    
    // Initialize
    self.username = [KCSKeyChain getStringForKey:@"username"];
    
    if (self.username == nil){
        // No user, generate it, note, use the APP KEY/APP SECRET!
        KCSAnalytics *analytics = [client analytics];
        
        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:[analytics UUID], @"username", [analytics UUID], @"UDID", nil];
        
        KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] userBaseURL] usingMethod:kPostRESTMethod];
        
        
        [userRequest setContentType:KCS_JSON_TYPE];
        [userRequest addBody:[userData JSONData]];
        
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            // Ok, we're probably authenticated
            if (response.responseCode != KCS_HTTP_STATUS_CREATED){
                // Crap, authentication failed, not really sure how to proceed here!!!
                // I really don't know what to do here, we can't continue... Something died...
                NSLog(@"KINVEY: Internal Error! (%@)", [[response.responseData objectFromJSONData] JSONString]);
                CFShow(response);
                
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                
                NSException* myException = [NSException
                                            exceptionWithName:@"KinveyInternalError"
                                            reason:@"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo"
                                            userInfo:[NSDictionary dictionaryWithObject:[[response.responseData objectFromJSONData] JSONString] forKey:@"error"]];
                
                @throw myException;                
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = [response.responseData objectFromJSONData];
            self.username = [dictionary objectForKey:@"username"];
            self.password = [dictionary objectForKey:@"password"];
            self.userId   = [dictionary objectForKey:@"_id"];
            
            assert(_username != nil && _password != nil && _userId != nil);
            
            [KCSKeyChain setString:self.username forKey:@"username"];
            [KCSKeyChain setString:self.password forKey:@"password"];
            [KCSKeyChain setString:self.userId forKey:@"userId"];
            
            [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone]];          
            
            // Indicate that threads are free to proceed
            client.userIsAuthenticated = YES;
            client.userAuthenticationInProgress = NO;
            
            // If we were provided with a request, then perform the original request
            [request start];
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            NSLog(@"KINVEY: Internal Error!");
            CFShow(error);

            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;

            NSException* myException = [NSException
                                        exceptionWithName:@"KinveyInternalError"
                                        reason:@"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo"
                                        userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            
            @throw myException;
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnection *conn){};
        
        [[userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
        
        
    } else {
        self.password = [KCSKeyChain getStringForKey:@"password"];
        [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone]];
        client.userIsAuthenticated = YES;
        
        // If we've received this with a request, make sure we start it...
        if (request != nil){
            [request start];
        }
    }
    
    
}

- (void)initializeCurrentUser
{
    [self initializeCurrentUserWithRequest:nil];
}

@end
