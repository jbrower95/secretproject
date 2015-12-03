//
//  API.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const API_REFRESH_FAILED_EVENT;
FOUNDATION_EXPORT NSString *const API_REFRESH_SUCCESS_EVENT;

@interface API : NSObject


/* Gets all friends from Facebook. */
+ (void)getAllFriendsWithBlock:(void(^)(NSArray *friends, NSError *error))block;


/* Checks into a place. */
+ (void)checkinToPlace:(NSString *)place atLongitude:(float)longitude atLatitude:(float)latitude withBlock:(void(^)(NSError *error))block;


/* Sends your location to another user. */
+ (void)giveLocationToUserWithId:(NSString *)user;

/* Returns true if the user is logged in (to facebook) */
+ (BOOL)isLoggedIn;

/* Call this to validate our facebook login token. */
+ (void)refreshFacebookLogin;

@end



