//
//  KCSTableViewControllerAddDelegate.h
//  KinveyLists
//
//  Created by Brian Wilson on 11/20/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCSTableViewControllerAddDelegate <NSObject>

- (void)detailsViewControllerDidCancel:(UIViewController *)controller;

- (void)detailsViewControllerDidSave:(UIViewController *)controller;


@end
