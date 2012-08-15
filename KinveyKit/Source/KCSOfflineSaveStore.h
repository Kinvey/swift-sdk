//
//  KCSOfflineSaveStore.h
//  KinveyKit
//
//  Created by Michael Katz on 8/6/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSStore.h"

@protocol KCSPersistable;

#define KCSStoreKeyUniqueOfflineSaveIdentifier @"KCSStore.OfflineSave.Identifier"
#define KCSStoreKeyOfflineSaveDelegate @"KCSStore.OfflineSave.Delegate"

#define KCS_ERROR_UNSAVED_OBJECT_IDS_KEY @"KCSStore.OfflineSave.UnsavedObjectIds"

@protocol KCSOfflineSaveStore <KCSStore> //Install by setting KCSStoreKeyUniqueOfflineSaveIdentifier, optional id<KCSOfflineSaveDelegate> KCSStoreKeyOfflineSaveDelegate
- (NSUInteger) numberOfPendingSaves;
@end

@protocol KCSOfflineSaveDelegate <NSObject>
@optional
/*
 Default is YES.
 */
- (BOOL) shouldSave:(id<KCSPersistable>)entity lastSaveTime:(NSDate*)timeSaved; //returning NO will cancel this save
- (void) willSave:(id<KCSPersistable>)entity lastSaveTime:(NSDate*)timeSaved; //give opporunity to modify item before save
- (void) didSave:(id<KCSPersistable>)entity; //give opportuntiy to update based upon returned entity
- (void) errorSaving:(id<KCSPersistable>)entity error:(NSError*)error; // if an error occurs, can have opportunity to modify save and repost. If the app goes offline, the save is automatically requed (with original save time) and this method is not called
@end