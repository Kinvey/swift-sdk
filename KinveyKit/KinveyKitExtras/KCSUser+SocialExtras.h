//
//  KCSUser+SocialExtras.h
//  KinveyKit
//
//  Copyright (c) 2012-2015 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

@class ACAccount;

#import "KCSBlockDefs.h"
#import "KinveyUser.h"

/**
 These are additional helpers for KCSUser to obtain credentials from social services. This requires linking in `Twitter.framework` and `Accounts.framework`.
 @since 1.9
 */
@interface KCSUser (SocialExtras)

/** Calls the Twitter reverse auth service to obtain an access token for the native user.
 
 In order for this method to succeed, you need to register an application with Twitter ( https://dev.twitter.com ) and supply the app's client key and client secret when setting up KCSClient (as `KCS_TWITTER_CLIENT_KEY`, and `KCS_TWITTER_CLIENT_SECRET`). 
 
 If sucessful, the completion block will provide a dictionary ready for `+[KCSUser loginWithWithSocialIdentity:accessDictionary:withCompletionBlock]`.
 
 If the user has multiple twitter accounts configured in Settings, this will use the first one in the list. If you wish to let the user select from multiple accounts, you will have to write your own helper to obtain the list of accounts and get the auth token. See https://dev.twitter.com/docs/ios/using-reverse-auth and https://developer.apple.com/library/ios/documentation/Accounts/Reference/ACAccountStoreClassRef/ACAccountStore.html .
 
 @param completionBlock the block to be called when the request completes or faults.
 @since 1.9
 */
+ (void) getAccessDictionaryFromTwitterFromPrimaryAccount:(KCSLocalCredentialBlock)completionBlock;

/** Calls the Twitter reverse auth service to obtain an access token for the native user.
 
 In order for this method to succeed, you need to register an application with Twitter ( https://dev.twitter.com ) and supply the app's client key and client secret when setting up KCSClient (as `KCS_TWITTER_CLIENT_KEY`, and `KCS_TWITTER_CLIENT_SECRET`).
 
 If sucessful, the completion block will provide a dictionary ready for `+[KCSUser loginWithWithSocialIdentity:accessDictionary:withCompletionBlock]`.
 
 If the user has multiple twitter accounts configured in Settings, use the `accountChooseBlock` to select which account to use. This can be done simply by choosing the first acocunt, or by presenting the user with a view to select from a list.
 
 @param completionBlock the block to be called when the request completes or faults.
 @param chooseBlock must return a twitter account from the supplied list. CANNOT be `nil`. This block may be called on an arbitrary thread. 
 @return KCSRequest object that represents the pending request made against the store. Since version 1.36.0
 @since 1.26.1
 */
+(KCSRequest*)getAccessDictionaryFromTwitterFromTwitterAccounts:(KCSLocalCredentialBlock)completionBlock
                                             accountChooseBlock:(ACAccount* (^)(NSArray* twitterAccounts))chooseBlock;

@end
