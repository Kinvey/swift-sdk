//
//  KCSLinkedInHelper.m
//  KinveyKit
//
//  Created by Michael Katz on 12/6/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSLinkedInHelper.h"

#import "NSString+KinveyAdditions.h"
#import "KCSGenericRestRequest.h"
#import "KCS_OAuthCore.h"
#import "KCSConnectionResponse.h"
#import "KCSLogManager.h"
#import "KCSErrorUtilities.h"

#import "KCSWebView.h"

@interface KCSLinkedInHelper() <KCSWebViewDelegate> {
    NSString* _tokenSecret;
    id<KCSWebViewDelegate> _oldDelegate;
    KCSLocalCredentialBlock _completionBlock;
}
@end

@implementation KCSLinkedInHelper


- (void) requestToken:(NSString*)linkedInScope completionBlock:(KCSLocalCredentialBlock)completionBlock
{
    NSString* urlString = @"https://api.linkedin.com/uas/oauth/requestToken";
    urlString = [urlString stringByAppendingQueryString:[@"scope=" stringByAppendingString:linkedInScope]];
    
    NSString *method = [KCSGenericRESTRequest getHTTPMethodForConstant:kPostRESTMethod];
    NSString* auth = KCS_OAuthorizationHeader([NSURL URLWithString:urlString], method, nil, self.apiKey, self.secretKey, nil, nil, nil);
    
    KCSGenericRESTRequest* request = [KCSGenericRESTRequest requestForResource:urlString usingMethod:kPostRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        NSString* results = [response stringValue];
        KCSLogTrace(@"LinkedIn requestToken response: %@", results);
        
        if ([response responseCode] < 300) {
            //OK
            _completionBlock = [completionBlock copy];
            [self getCredentialsFromWeb:results];
        } else {
            // error loading page
            NSError* error = [NSError errorWithDomain:KCSNetworkErrorDomain code:[response responseCode] userInfo:@{NSURLErrorFailingURLStringErrorKey : urlString, NSLocalizedDescriptionKey : @"Reached LinkedIn But was unable to show the credentials page.", NSLocalizedFailureReasonErrorKey : results }];
            completionBlock(nil, error);
        }
        
    } failureAction:^(NSError *errorOrNil) {
        NSError* error = [NSError errorWithDomain:KCSNetworkErrorDomain code:errorOrNil.code userInfo:@{ NSUnderlyingErrorKey : errorOrNil, NSURLErrorFailingURLStringErrorKey : urlString, NSLocalizedDescriptionKey : @"Unable to reach LinkedIn to obtain OAuth token." }];
        completionBlock(nil, error);
    } progressAction:nil];
    [request.headers setValue:auth forKey:@"Authorization"];
    
    [request start];
}

NSString* KCS_GetOAuthTokenFromQuery(NSString* results, NSString* parameter)
{
    NSString* oauthToken = nil;
    
    NSArray* pairs = [results componentsSeparatedByString:@"&"];
    for (NSString* pair in pairs) {
        NSArray* keyval = [pair componentsSeparatedByString:@"="];
        NSString* key = keyval[0];
        NSString* value = keyval[1];
        if ([key isEqualToString:parameter]) {
            oauthToken = value;
        }
    }
    
    return oauthToken;
}


- (void) getCredentialsFromWeb:(NSString*)results
{
    NSString* oauthToken = KCS_GetOAuthTokenFromQuery(results, @"oauth_token");
    _tokenSecret = KCS_GetOAuthTokenFromQuery(results, @"oauth_token_secret");
    
    NSString* webUrlString = [@"https://www.linkedin.com/uas/oauth/authorize" stringByAppendingQueryString:[NSString stringWithFormat:@"oauth_token=%@", oauthToken]];
    
    //step 2: Show the user a browser displaying the LinkedIn login page.
    
    _oldDelegate = self.webview.delegate;
    self.webview.delegate  = self;
    
    [self.webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:webUrlString]]];
}

- (void)webView:(KCSWebViewClass*)webView didFailLoadWithError:(NSError *)error
{
    self.webview.delegate = _oldDelegate;
    NSError* wrappedError = [NSError errorWithDomain:KCSNetworkErrorDomain code:error.code userInfo:@{ NSUnderlyingErrorKey : error, NSLocalizedDescriptionKey : @"Unable to reach LinkedIn to obtain OAuth token." }];
    _completionBlock(nil, wrappedError);
}

- (BOOL)webView:(KCSWebViewClass*)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL* urlToLoad = [request URL];
    NSString* linkString = [urlToLoad absoluteString];
    
    if ([linkString hasPrefix:_cancelRedirect]) {
        //cancel callback
        
        self.webview.delegate = _oldDelegate;

        NSError* canceledError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSDeniedError userInfo:@{NSURLErrorFailingURLStringErrorKey : linkString, NSLocalizedDescriptionKey : @"User cancelled or refused to grant access."}];
        _completionBlock(nil, canceledError);
        return NO;
    } else if ([linkString hasPrefix:_acceptRedirect]) {
        self.webview.delegate = _oldDelegate;
        
        //accept callback        
        // hdlinked://linkedin/oauth?oauth_token=<token value>&oauth_verifier=63600     OR
        //             hdlinked://linkedin/oauth?user_refused
        
        NSString* queryString = [urlToLoad query];
        NSString* token = KCS_GetOAuthTokenFromQuery(queryString, @"oauth_token");
        NSString* verifier = KCS_GetOAuthTokenFromQuery(queryString, @"oauth_verifier");
        
        if (token != nil && verifier != nil) {
            [self getAccessToken:token verifier:verifier];
        } else {
            NSError* error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSDeniedError userInfo:@{NSURLErrorFailingURLStringErrorKey : linkString, NSLocalizedDescriptionKey : @"User cancelled or refused to grant access.", NSLocalizedFailureReasonErrorKey : queryString }];
            _completionBlock(nil, error);
        }
        return NO;
    }
    
    return YES;
}


//step 4: get the access token
- (void) getAccessToken:(NSString*)token verifier:(NSString*) verifier
{
    NSString* urlString =  @"https://api.linkedin.com/uas/oauth/accessToken";
    NSString *method = [KCSGenericRESTRequest getHTTPMethodForConstant:kPostRESTMethod];
    NSString* auth = KCS_OAuthorizationHeader([NSURL URLWithString:urlString], method, nil, self.apiKey, self.secretKey, token, _tokenSecret, @{@"oauth_verifier" : verifier});
    
    KCSGenericRESTRequest* request = [KCSGenericRESTRequest requestForResource:urlString usingMethod:kPostRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        NSString* results = [response stringValue];        
        
        NSString* oauthToken = KCS_GetOAuthTokenFromQuery(results, @"oauth_token");
        NSString* tokenSecret = KCS_GetOAuthTokenFromQuery(results, @"oauth_token_secret");
        
        NSDictionary* accessDictionary = @{ @"access_token" : oauthToken, @"access_token_secret" : tokenSecret, @"consumer_key" : self.apiKey, @"consumer_secret" : self.secretKey};
        _completionBlock(accessDictionary, nil);
    } failureAction:^(NSError *errorOrNil) {
        //TODO: wrap error
        _completionBlock(nil, errorOrNil);
    } progressAction:nil];
    
    [request.headers setValue:auth forKey:@"Authorization"];
    [request start];
}


@end
