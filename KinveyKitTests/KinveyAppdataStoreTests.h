//
//  KinveyCollectionStoreTests.h
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

@class KCSCollection;
@class KCSAppdataStore;
@interface KinveyAppdataStoreTests : SenTestCase {
    KCSCollection* _collection;
    KCSAppdataStore* _store;
}

@end
