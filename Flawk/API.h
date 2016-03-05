//
//  API.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>
#import "Friend.h" 
#import "PersistentCheckin.h"
#import "LocationDaemon.h"

FOUNDATION_EXPORT NSString *const API_REFRESH_FAILED_EVENT;
FOUNDATION_EXPORT NSString *const API_REFRESH_SUCCESS_EVENT;

@interface API : NSObject <CLLocationManagerDelegate> {
    NSMutableArray<Friend *> *friends;
    Friend *this_user;
    CLLocationManager *manager;
    NSMutableArray<PersistentCheckin *> *checkins;
    LocationDaemon *locationDaemon;
    Firebase *firebase;
}

@property (nonatomic, retain) Firebase *firebase;
@property (nonatomic, retain) CLLocationManager *manager;
@property (nonatomic, retain) NSMutableArray *friends;
@property (nonatomic, retain) Friend *this_user;
@property (nonatomic, retain) NSMutableArray<PersistentCheckin *> *checkins;

/* Gets all friends from Facebook. */
- (void)getAllFriendsWithBlock:(void(^)(NSArray *friends, NSError *error))block;

/* Checks into a place. */
- (void)checkinToPlace:(NSString *)place atLongitude:(float)longitude atLatitude:(float)latitude withBlock:(void(^)(NSError *error))block;

/* Sends your location to another user. */
- (void)shareLocationWithUser:(Friend *)user;

/* Returns true if the user is logged in (to facebook) */
- (BOOL)isLoggedIn;

/* Tries to login the user with facebook */
- (void)login;

/* Parses friends and caches them */
- (void)parseFriends:(NSArray *)friends;

/* Initializes parse by logging in. */
- (void)initParse;

/* Request where at */
- (void)requestWhereAt:(Friend *)other;

/* The shared API access */
+ (instancetype)sharedAPI;

- (void)setLoggedInUser:(NSString *)name token:(NSString *)token;

/* Handles a push notification */
- (void)handlePush:(NSDictionary *)push;

- (void)shareLocationWithUser:(Friend *)user completion:(void (^)())completionHandler;

- (void)sendMessageToUser:(Friend *)pal content:(NSString *)text completionHandler:(void (^)())completionHandler;

- (void)getLocationAndAreaWithBlock:(void (^)())completion;

- (void)shareLocationWithUsers:(NSSet *)users completion:(void (^)(BOOL))completionHandler;

- (void)startMonitoringRegion:(CLRegion *)region withLocationName:(NSString *)name area:(NSString *)area friends:(NSSet *)friends;

- (void)loadExtendedUserInfoFromFacebook;

- (Friend *)currentUser;

- (void)save;

- (void)initLocations;
@end



