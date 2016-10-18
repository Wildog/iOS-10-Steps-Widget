//
//  AppDelegate.m
//  LineChart
//
//  Created by Wildog on 9/16/16.
//  Copyright © 2016 Wildog. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.dog.wil.steps"];
    if ([shortcutItem.type isEqual: @"dog.wil.steps.set-unit-to-km"]) {
        [shared setObject:@"km" forKey:@"unit"];
    } else if ([shortcutItem.type isEqual: @"dog.wil.steps.set-unit-to-mi"]) {
        [shared setObject:@"mi" forKey:@"unit"];
    }
    [shared synchronize];
    [self createShortcutItems];
}

- (void)createShortcutItems {
    UIApplicationShortcutIcon *kmIcon = nil;
    UIApplicationShortcutIcon *miIcon = nil;
    NSUserDefaults *shared = [[NSUserDefaults alloc] initWithSuiteName:@"group.dog.wil.steps"];
    if ([[shared stringForKey:@"unit"]  isEqual: @"mi"]) {
        miIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTaskCompleted];
        kmIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTask];
    } else {
        kmIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTaskCompleted];
        miIcon = [UIApplicationShortcutIcon iconWithType:UIApplicationShortcutIconTypeTask];
    }
    UIApplicationShortcutItem *kmItem = [[UIApplicationShortcutItem alloc] initWithType:@"dog.wil.steps.set-unit-to-km" localizedTitle:@"Set unit to km" localizedSubtitle:nil icon:kmIcon userInfo:nil];
    UIApplicationShortcutItem *miItem = [[UIApplicationShortcutItem alloc] initWithType:@"dog.wil.steps.set-unit-to-mi" localizedTitle:@"Set unit to mi" localizedSubtitle:nil icon:miIcon userInfo:nil];
    NSArray *items = @[kmItem, miItem];
    [UIApplication sharedApplication].shortcutItems = items;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self createShortcutItems];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
