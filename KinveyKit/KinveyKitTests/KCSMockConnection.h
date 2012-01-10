//
//  KCSMockConnection.h
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnection.h"

@class KCSConnectionResponse;

@interface KCSMockConnection : KCSConnection

@property (nonatomic) BOOL connectionShouldFail;
@property (nonatomic) BOOL connectionShouldReturnNow;

@property (retain, nonatomic) KCSConnectionResponse *responseForSuccess;
@property (retain, nonatomic) NSArray *progressActions;
@property (retain, nonatomic) NSError *errorForFailure;

// Delay in MSecs betwen each action...
@property (nonatomic) double delayInMSecs;

@property (retain, nonatomic) NSURLRequest *providedRequest;
@property (retain, nonatomic) NSURLCredential *providedCredentials;



@end
