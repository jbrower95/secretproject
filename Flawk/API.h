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
#import "Request.h"

FOUNDATION_EXPORT NSString *const API_REFRESH_FAILED_EVENT;
FOUNDATION_EXPORT NSString *const API_REFRESH_SUCCESS_EVENT;
FOUNDATION_EXPORT NSString *const API_RECEIVED_FRIEND_REQUEST_EVENT;

@interface API : NSObject <CLLocationManagerDelegate> {
    NSMutableArray<Friend *> *friends;
    NSMutableArray<Friend *> *confirmedFriends;
    NSMutableArray<Request *> *outstandingFriendRequests;
    NSMutableArray<Request *> *sentFriendRequests;
    
    Friend *this_user;
    CLLocationManager *manager;
    NSMutableArray<PersistentCheckin *> *checkins;
    LocationDaemon *locationDaemon;
    Firebase *firebase;
    
    NSMutableArray<NSNumber *> *friendHandles;
}

@property (nonatomic, retain) Firebase *firebase;
@property (nonatomic, retain) CLLocationManager *manager;
@property (nonatomic, retain) NSMutableArray *friends;
@property (nonatomic, retain) NSMutableArray *confirmedFriends;
@property (nonatomic, retain) Friend *this_user;
@property (nonatomic, retain) NSMutableArray<PersistentCheckin *> *checkins;
@property (nonatomic, retain) NSMutableArray<Request *> *outstandingFriendRequests;
@property (nonatomic, retain) NSMutableArray<Request *> *sentFriendRequests;
@property (nonatomic, retain) NSMutableArray<NSNumber *> *friendHandles;
@property (nonatomic, retain) NSMutableArray<NSDictionary *> *locationChoices;
/* Gets all friends from Facebook. */
- (void)getAllFriendsWithBlock:(void(^)(NSArray *friends, NSError *error))block;

/* Checks into a place. */
- (void)checkinToPlace:(NSString *)place atLongitude:(float)longitude atLatitude:(float)latitude withBlock:(void(^)(NSError *error))block;

/* Sends your location to another user. */
- (void)shareLocationWithUser:(Friend *)user completion:(void (^)(BOOL success, NSError *error))completionHandler;

/* Returns true if the user is logged in (to facebook) */
- (BOOL)isLoggedIn;

/* Tries to login the user with facebook */
- (void)login;

/* Parses friends and caches them */
- (void)parseFriends:(NSArray *)friends;

/* Initializes parse by logging in. */
- (void)initParse;

/* Request where at */
- (void)requestWhereAt:(Friend *)other completion:(void (^)())completion;

/* The shared API access */
+ (instancetype)sharedAPI;

- (void)setLoggedInUser:(NSString *)name token:(NSString *)token;

/* Handles a push notification */
- (void)handlePush:(NSDictionary *)push;

- (void)sendMessageToUser:(Friend *)pal content:(NSString *)text completionHandler:(void (^)())completionHandler;

- (void)getLocationAndAreaWithBlock:(void (^)())completion;

- (void)shareLocationWithUsers:(NSMutableSet *)users completion:(void (^)(BOOL, NSError*))completionHandler;

- (void)startMonitoringRegion:(CLRegion *)region withLocationName:(NSString *)name area:(NSString *)area friends:(NSSet *)friends;

- (void)loadExtendedUserInfoFromFacebook;

- (Friend *)currentUser;

- (void)save;

- (void)initLocations;
@end



