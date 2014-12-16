//
//  AppDelegate.m
//  Glucograph
//
//  Created by Sergey Seitov on 07.04.14.
//  Copyright (c) 2014 Sergey Seitov. All rights reserved.
//

#import "AppDelegate.h"
#import "StorageManager.h"
#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}

- (BOOL)iCloudSynchro
{
    if (![[NSUbiquitousKeyValueStore defaultStore] synchronize]) {
        NSLog(@"error synchro");
        return NO;
    }
    
    double icloudDate = [[NSUbiquitousKeyValueStore defaultStore] doubleForKey:@"LAST_MODIFIED"];
    double localDate = [[NSUserDefaults standardUserDefaults] doubleForKey:@"localModified"];
    if (icloudDate > localDate) {
        NSData* data = [[NSUbiquitousKeyValueStore defaultStore] dataForKey:@"DB_CONTENT"];
        [[StorageManager sharedStorageManager] setDBFromData:data];
        return YES;
    } else if (icloudDate < localDate) {
        NSData* data = [[StorageManager sharedStorageManager] getDBData];
        [[NSUbiquitousKeyValueStore defaultStore] setData:data forKey:@"DB_CONTENT"];
        [[NSUbiquitousKeyValueStore defaultStore] setDouble:localDate forKey:@"LAST_MODIFIED"];
        [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    }
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self iCloudSynchro];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    UINavigationController* nav = (UINavigationController*)_window.rootViewController;
    ViewController* top = (ViewController*)nav.topViewController;
	[top updateDateInterval];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
