//
//  KCSUser+SocialExtras.m
//  KinveyKit
//
//  Created by Michael Katz on 9/18/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSUser+SocialExtras.h"

#import "KCSErrorUtilities.h"

#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "KCS_TWSignedRequest.h"

@implementation KCSUser (SocialExtras)

+ (BOOL) checkForTwitterKeys
{
    NSString* twitterKey = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_KEY];
    NSString* twitterSecret = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_SECRET];
    return [twitterKey length] > 0 && [twitterSecret length] > 0;
}

+ (BOOL) checkForTwitterCredentials
{
    return [TWTweetComposeViewController canSendTweet];
}

+ (BOOL) canUseNativeTwitter
{
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:@"5.0" options:NSNumericSearch] != NSOrderedAscending);
    return osVersionSupported && [self checkForTwitterCredentials] && [self checkForTwitterKeys];
}

+ (void) getAccessDictionaryFromTwitterFromPrimaryAccount:(KCSLocalCredentialBlock)completionBlock
{
    //  Check to make sure that the user has added his credentials
    BOOL hasKeys = [self checkForTwitterKeys];
    BOOL hasTwitterCred = [self checkForTwitterCredentials];
    if (hasKeys && hasTwitterCred) {
        
        dispatch_queue_t current_queue = dispatch_get_current_queue();
        //
        //  Step 1)  Ask Twitter for a special request_token for reverse auth
        //
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
        
        // "reverse_auth" is a required parameter
        NSDictionary* dict = @{ @"x_auth_mode" : @"reverse_auth"};
        KCS_TWSignedRequest* signedRequest = [[[KCS_TWSignedRequest alloc] initWithURL:url parameters:dict requestMethod:kPostRESTMethod] autorelease];
        [signedRequest performRequestWithHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (!data || [(NSHTTPURLResponse*)response statusCode] >= 400) {
                NSError* tokenError =[KCSErrorUtilities createError:nil description:@"Unable to obtain a Twitter access token" errorCode:KCSDeniedError domain:KCSUserErrorDomain sourceError:error];
                dispatch_async(current_queue, ^{
                    completionBlock(nil, tokenError);
                });
            } else {
                NSString *signedReverseAuthSignature = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
                
                //
                //  Step 2)  Ask Twitter for the user's auth token and secret
                //           include x_reverse_auth_target=CK2 and x_reverse_auth_parameters=signedReverseAuthSignature parameters
                //
                dispatch_async(dispatch_get_current_queue(), ^{
                    NSString* twitterKey = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_KEY];

                    NSDictionary *step2Params = @{@"x_reverse_auth_target" : twitterKey, @"x_reverse_auth_parameters" : signedReverseAuthSignature};
                    NSURL *authTokenURL = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
                    TWRequest *step2Request = [[TWRequest alloc] initWithURL:authTokenURL parameters:step2Params requestMethod:TWRequestMethodPOST];
                    
                    //  Obtain the user's permission to access the store
                    //
                    //  NB: You *MUST* keep the ACAccountStore around for as long as you need an ACAccount around.  See WWDC 2011 Session 124 for more info.
                    ACAccountStore* accountStore = [[ACAccountStore alloc] init];
                    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
                    
                    [accountStore requestAccessToAccountsWithType:twitterType withCompletionHandler:^(BOOL granted, NSError *error) {
                        if (!granted) {
                            NSError* tokenError =[KCSErrorUtilities createError:nil description:@"User rejected access to Twitter account" errorCode:KCSDeniedError domain:KCSUserErrorDomain sourceError:error];
                            dispatch_async(current_queue, ^{
                                completionBlock(nil, tokenError);
                            });
                        } else {
                            // obtain all the local account instances
                            NSArray *accounts = [accountStore accountsWithAccountType:twitterType];
                            
                            // we can assume that we have at least one account thanks to +[TWTweetComposeViewController canSendTweet], let's return it
                            [step2Request setAccount:[accounts objectAtIndex:0]];
                            [step2Request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                                if (!responseData || ((NSHTTPURLResponse*)urlResponse).statusCode >= 400) {
                                    NSError* tokenError = [KCSErrorUtilities createError:nil description:@"Unable to obtain a Twitter access token" errorCode:KCSDeniedError domain:KCSUserErrorDomain sourceError:error];
                                    dispatch_async(current_queue, ^{
                                        completionBlock(nil, tokenError);
                                    });
                                }
                                else {
                                    NSString *responseStr = [[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding] autorelease];
                                    //will get back in the form of oauth_token=XXXX&oauth_token_secret=YYYY&user_id=ZZZZ&screen_name=AAAAA
                                    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithCapacity:2];
                                    NSArray* components = [responseStr componentsSeparatedByString:@"&"];
                                    for (NSString* component in components) {
                                        NSArray* items = [component componentsSeparatedByString:@"="];
                                        if (items.count == 2) {
                                            NSString* key = [items objectAtIndex:0];
                                            if ([key isEqualToString:@"oauth_token"]) {
                                                [dictionary setValue:[items objectAtIndex:1] forKey:@"access_token"];
                                            } else if ([key isEqualToString:@"oauth_token_secret"]) {
                                                [dictionary setValue:[items objectAtIndex:1] forKey:@"access_token_secret"];
                                            }
                                        }
                                    }
                                    dispatch_async(current_queue, ^{
                                        completionBlock(dictionary, nil);
                                    });
                                }
                            }];
                        }
                    }];
                });
            }
        }];

    } else {
        NSDictionary* info;
        NSString* description;
        if (!hasKeys) {
            description = @"Cannot use Twitter reverse auth without consumer app information";
            info = [KCSErrorUtilities createErrorUserDictionaryWithDescription:description withFailureReason:@"Missing Consumer Key and/or Consumer Secret" withRecoverySuggestion:@"Set KCS_TWITTER_CLIENT_KEY and KCS_TWITTER_CLIENT_SECRET in the Kinvey client options dictionary" withRecoveryOptions:nil];
        } else {
            description = @"Twitter account not configured in settings";
            info = [KCSErrorUtilities createErrorUserDictionaryWithDescription:description withFailureReason:nil withRecoverySuggestion:@"Configure twitter account in settings" withRecoveryOptions:nil];
        }
        NSError* error = [KCSErrorUtilities createError:info description:description errorCode:KCSDeniedError domain:KCSUserErrorDomain];
        completionBlock(nil, error);
    }
}



@end
