//
//  KCSMockURLConnection.h
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

// Fake connection object
@interface KCSMockURLConnection : NSURLConnection

@property (assign, nonatomic) id delegate;
@property (retain, nonatomic) NSURLRequest *request;

@end
