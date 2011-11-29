//
//  KCSAsyncConnection.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnection.h"

@interface KCSAsyncConnection : KCSConnection


/*! Stored data in response to a request */
@property (retain, readonly) NSMutableData *activeDownload;

/*! The (HTTP) response from the server.  We only store the final responding server in a redirect chain */
@property (retain) NSURLResponse *lastResponse;

/*! Stored credentials for Kinvey access */
@property (retain) NSURLCredential *basicAuthCred;

/*! How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

@property (nonatomic, retain) NSURLRequest *request;

@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) double percentComplete;
@property (nonatomic) NSUInteger percentNotificationThreshold;





@end
