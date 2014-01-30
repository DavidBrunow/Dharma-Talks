//
//  DHBAppDelegate.h
//  Mission Dharma
//
//  Created by David Brunow on 7/12/13.
//  Copyright (c) 2013 David Brunow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DHBAudioNavigationViewController.h"
#import "DHBPodcast.h"
#import "Reachability.h"

@interface DHBAppDelegate : UIResponder <UIApplicationDelegate> {
    Reachability *hostReachable;
}

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (strong, nonatomic) DHBAudioNavigationViewController *audioNavigationViewController;
@property (strong, nonatomic) DHBPodcast *podcast;
@property (nonatomic) bool isConnectedViaWifi;
@property (strong, nonatomic) UIColor *lightColor;
@property (strong, nonatomic) UIColor *darkColor;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
