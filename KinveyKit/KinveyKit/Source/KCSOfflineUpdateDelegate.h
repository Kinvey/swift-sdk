//
//  KCSOfflineUpdateDelegate.h
//  KinveyKit
//
//  Copyright (c) 2013 Kinvey. All rights reserved.
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


#import <Foundation/Foundation.h>

//TODO: document
//TODO: document!!
//TODO: remove old keys and values
//TODO: update guide
//DOC: can be called on any queue

/*
 @since 1.23.0
 */
@protocol KCSOfflineUpdateDelegate <NSObject>

@optional
- (BOOL) shouldSaveObject:(NSString*)objectId inCollection:(NSString*)collectionName lastAttemptedSaveTime:(NSDate*)saveTime;
- (void) willSaveObject:(NSString*)objectId inCollection:(NSString*)collectionName;
- (void) didSaveObject:(NSString*)objectId inCollection:(NSString*)collectionName;

- (BOOL) shouldDeleteObject:(NSString*)objectId inCollection:(NSString*)collectionName lastAttemptedSaveTime:(NSDate*)saveTime;
- (void) willDeleteObject:(NSString*)objectId inCollection:(NSString*)collectionName;
- (void) didDeleteObject:(NSString*)objectId inCollection:(NSString*)collectionName;

- (void) didEnqueueObject:(NSString*)objectId inCollection:(NSString*)collectionName;
- (BOOL) shouldEnqueueObject:(NSString*)objectId inCollection:(NSString*)collectionName onError:(NSError*)error;

@end
