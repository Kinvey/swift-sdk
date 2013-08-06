//
//  KCSLinkedDataStoreTests.h
//  KinveyKit
//
//  Created by Michael Katz on 5/29/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
 
@class KCSLinkedAppdataStore;
@class KCSCollection;

@interface KCSLinkedAppdataStoreTests : SenTestCase {
    KCSLinkedAppdataStore* store;
    KCSCollection* _collection;
}

@end
