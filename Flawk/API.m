//
//  API.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "API.h"
#import "Friend.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>

NSString *const API_REFRESH_FAILED_EVENT = @"APIRefreshFailedEvent";
NSString *const API_REFRESH_SUCCESS_EVENT = @"APIRefreshSuccessEvent";

@implementation API

@synthesize friends, this_user;


- (id)init {
    if (self = [super init]) {
        friends = [[NSMutableArray alloc] init];
    }
    
    return self;
}


/* Gets all friends from Facebook. */
- (void)getAllFriendsWithBlock:(void(^)(NSArray *friends, NSError *error))block {
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields" : @"id, name, email"}];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error == nil) {
            // No problemo.
            NSDictionary *parsedResult = (NSDictionary *)result;
            
            NSArray *newFriends = [parsedResult objectForKey:@"data"];
            
            if (newFriends != nil) {
                NSLog(@"Parsing friends.");
                [[API sharedAPI] parseFriends:newFriends];
                block(self.friends, nil);
            } else {
                NSLog(@"No friends from Facebook.");
            }
            
        } else {
            // Error
            if ([error code] == FBSDKGraphRequestGraphAPIErrorCode) {
                NSLog(@"Experienced an error with the graph api.");
                NSLog(@"%@", [[error userInfo] objectForKey:FBSDKGraphRequestErrorParsedJSONResponseKey]);
                block([NSArray array], error);
            }
            
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (BOOL)isLoggedIn {
    return [FBSDKAccessToken currentAccessToken] != nil;
}

/* Checks into a place. */
- (void)checkinToPlace:(NSString *)place atLongitude:(float)longitude atLatitude:(float)latitude withBlock:(void(^)(NSError *error))block {
    
    // TODO: Send a request to the server to share your location
    if (block != nil) {
        block(nil);
    }
}


/* Sends your location to another user. */
- (void)giveLocationToUserWithId:(NSString *)user withBlock:(void(^)(NSError *error))block {
    if (block != nil) {
        block(nil);
    }
}


- (void)refreshFacebookLogin {
    [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        if (error != nil) {
            NSLog(@"[API] Critical -- Could not refresh Facebook login.");
            [[NSNotificationCenter defaultCenter] postNotificationName:API_REFRESH_FAILED_EVENT object:self];
        } else {
            // Success -- tell no one anything.
            NSLog(@"[API] Refreshed token successfully.");
            [[NSNotificationCenter defaultCenter] postNotificationName:API_REFRESH_SUCCESS_EVENT object:self];
        }
        
    }];
}

- (void)parseFriends:(NSArray *)f {
    [friends removeAllObjects];
    for (NSDictionary *dict in f) {
        Friend *friend = [[Friend alloc] initWithFacebookDict:dict];
        [friends addObject:friend];
    }
}


- (void)initParse {
    
    FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
    
    if (token == nil) {
        NSLog(@"[API] Couldn't initialize Parse -- token was nil.");
        return;
    }
    
    [PFFacebookUtils logInInBackgroundWithAccessToken:token block:^(PFUser * _Nullable user, NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"Error signing in: %@", [error localizedFailureReason]);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ParseFailure" object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ParseSuccess" object:self];
            
            PFInstallation *currentInstallation = [PFInstallation currentInstallation];
            [currentInstallation setObject:[token userID] forKey:@"facebookId"];
            [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
                if (error == nil) {
                    NSLog(@"[API] Successfully configured installation..");
                } else {
                    NSLog(@"[API] Failed to configure installation. - %@", [error localizedFailureReason]);
                }
            }];
        }
    }];
    
}

- (void)requestWhereAt:(Friend *)other {
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"facebookId" equalTo:[other fbid]];
    
    PFPush *push = [PFPush push];
    [push setQuery:query];
    [push sendPushInBackground];
}


static API *sharedAPI;

+ (id)sharedAPI {
    if (sharedAPI == nil) {
        sharedAPI = [[API alloc] init];
    }
    
    return sharedAPI;
}

@end
