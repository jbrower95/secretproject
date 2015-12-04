//
//  AppDelegate.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "AppDelegate.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <Parse/Parse.h>
#import <ParseFacebookUtilsV4/PFFacebookUtils.h>
#import "API.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    [Parse setApplicationId:@"gWEenk0TPTnbU18Ug0SpyAXR2Omh5Jk57wvAgI8M"
                  clientKey:@"W7vgDEUea8r184Ptyt9vbx7C9wfD5WXq7M1Rmo0z"];
    [PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation saveEventually];
    
    
    UIMutableUserNotificationAction *sendLocationAction =
    [[UIMutableUserNotificationAction alloc] init];

    // Define an ID string to be passed back to your app when you handle the action
    sendLocationAction.identifier = @"sendLocationAction";
    
    // Localized string displayed in the action button
    sendLocationAction.title = @"Share";
    
    // If you need to show UI, choose foreground
    sendLocationAction.activationMode = UIUserNotificationActivationModeBackground;
    
    // Destructive actions display in red
    sendLocationAction.destructive = NO;
    
    // Set whether the action requires the user to authenticate
    sendLocationAction.authenticationRequired = NO;
    
    
    UIMutableUserNotificationAction *replyAction =
    [[UIMutableUserNotificationAction alloc] init];
    
    // Define an ID string to be passed back to your app when you handle the action
    replyAction.identifier = @"replyAction";
    
    // Localized string displayed in the action button
    replyAction.title = @"Reply";
    
    // If you need to show UI, choose foreground
    replyAction.activationMode = UIUserNotificationActivationModeBackground;
    
    // Destructive actions display in red
    replyAction.destructive = NO;
    
    // Set whether the action requires the user to authenticate
    replyAction.authenticationRequired = NO;
    
    // Make this take text input.
    replyAction.behavior = UIUserNotificationActionBehaviorTextInput;
    
    
    
    UIMutableUserNotificationCategory *inviteCategory =
    [[UIMutableUserNotificationCategory alloc] init];
    
    // Identifier to include in your push payload and local notification
    inviteCategory.identifier = @"REQUEST_LOCATION_CATEGORY";
    
    // Add the actions to the category and set the action context
    [inviteCategory setActions:@[sendLocationAction, replyAction]
                    forContext:UIUserNotificationActionContextDefault];
    
    // Set the actions to present in a minimal context
    [inviteCategory setActions:@[sendLocationAction, replyAction]
                    forContext:UIUserNotificationActionContextMinimal];

    
    NSSet *categories = [NSSet setWithObjects:inviteCategory, nil];
                         
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:categories];
                         
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Store the deviceToken in the current Installation and save it to Parse
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    [currentInstallation saveInBackground];
}


- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forRemoteNotification:(NSDictionary *)userInfo
  completionHandler:(void (^)(void))completionHandler
{
    
    if (identifier != nil) {
        
        if ([identifier isEqualToString:@"replyAction"]) {
            NSLog(@"do something else");
            // unimplemented
            
        } else if ([identifier isEqualToString:@"sendLocationAction"]) {
            NSLog(@"%@", userInfo);
            
            [[API sharedAPI] shareLocationWithUser:[[Friend alloc] initWithName:nil fbId:[userInfo objectForKey:@"from"]] completion:completionHandler];
        }
    } else {
        completionHandler();
    }
}


- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation
            ];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    NSLog(@"Received notification: %@", userInfo);
    [[API sharedAPI] handlePush:userInfo];
}

@end
