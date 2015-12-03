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

NSString *const API_REFRESH_FAILED_EVENT = @"APIRefreshFailedEvent";
NSString *const API_REFRESH_SUCCESS_EVENT = @"APIRefreshSuccessEvent";

@implementation API

@synthesize friends;


- (id)init {
    if (self = [super init]) {
        friends = [[NSMutableArray alloc] init];
    }
    
    return self;
}


/* Gets all friends from Facebook. */
- (void)getAllFriendsWithBlock:(void(^)(NSArray *friends, NSError *error))block {
    
    NSMutableArray *friends = [[NSMutableArray alloc] init];
    
    Friend *friend = [[Friend alloc] initWithName:@"Justin Brower" fbId:@"none"];
    [friends addObject:friend];
    
    Friend *friendTwo = [[Friend alloc] initWithName:@"Nate Parrott" fbId:@"none"];
    
    [friendTwo setLastLocation:CGPointMake(-42, 61) place:@"Sci Li" area:@"College Hill, RI"];
    [friends addObject:friendTwo];
    
    Friend *friendThree = [[Friend alloc] initWithName:@"Amy Butcher" fbId:@"none"];
    [friends addObject:friendThree];
    
    
    // TODO: grab all friends from Facebook API.
    if (block != nil) {
        block(friends, nil);
    }
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
    
    NSLog(@"Parsed %lu friends.", [f count]);
}

static API *sharedAPI;

+ (id)sharedAPI {
    if (sharedAPI == nil) {
        sharedAPI = [[API alloc] init];
    }
    
    return sharedAPI;
}

@end
