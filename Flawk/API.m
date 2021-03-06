//
//  API.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "API.h"
#import "Friend.h"
#import "AppDelegate.h"
#import "PushMaster.h"
#import <FBSDKLoginKit/FBSDKLoginKit.h>
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#include <pthread.h>

NSString *const API_REFRESH_FAILED_EVENT = @"APIRefreshFailedEvent";
NSString *const API_REFRESH_SUCCESS_EVENT = @"APIRefreshSuccessEvent";
NSString *const API_RECEIVED_FRIEND_REQUEST_EVENT = @"APIReceivedFriendRequestEvent";

NSString *const FIREBASE_URI = @"https://flawkdb.firebaseio.com";

@implementation API

@synthesize manager; 

@synthesize friends, this_user, checkins, firebase, locationChoices, outstandingFriendRequests, sentFriendRequests, confirmedFriends, friendHandles;

- (id)init {
    if (self = [super init]) {
        self.firebase = [[Firebase alloc] initWithUrl:FIREBASE_URI];
        self.friends = [[NSMutableArray alloc] init];
        self.this_user = [[Friend alloc] init];
        self.checkins = [[NSMutableArray alloc] init];
        self.outstandingFriendRequests = [[NSMutableArray alloc] init];
        self.confirmedFriends = [[NSMutableArray alloc] init];
        self.sentFriendRequests = [[NSMutableArray alloc] init];
        self.friendHandles = [[NSMutableArray alloc] init];
        self.locationChoices = [[NSMutableArray alloc] init];
        checkinAvailable = NO;
    }

    NSData *friendsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"friends"];
    
    if (friendsData != nil) {
        NSLog(@"[API] Reloading saved friends...");
        self.friends = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithData:friendsData];
    } else {
        NSLog(@"[API] Couldn't reload friends.");
    }
    
    NSData *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"this_user"];
    
    if (userData != nil) {
        self.this_user = (Friend *)[NSKeyedUnarchiver unarchiveObjectWithData:userData];
    }
    
    
    return self;
}

- (void)setupListeners {
    FQuery *query = [[[self.firebase childByAppendingPath:@"requests"] queryOrderedByChild:@"to"] queryEqualToValue:[NSString stringWithFormat:@"facebook:%@",[self this_user].fbid]];
    NSLog(@"Listening for requests for fbid: %@", [self this_user].fbid);
    // Listen for incoming friend requests
    [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if (snapshot.exists) {
            [self.outstandingFriendRequests removeAllObjects];
            FDataSnapshot *child;
            const int FIVE_MINUTES = 300;
            for (child in snapshot.children) {
                Request *request = [[Request alloc] initWithSnapshot:child];
                // Hmm..
                if (!([request accepted] && ([[NSDate date] timeIntervalSince1970] - [request timestamp]) > FIVE_MINUTES)) {
                    [self.outstandingFriendRequests addObject:request];
                    NSLog(@"Received Friend Request! (from=%@, to=%@)", [request from], [request to]);
                }
            }
        } else {
            [self.outstandingFriendRequests removeAllObjects];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:API_RECEIVED_FRIEND_REQUEST_EVENT object:nil];
    }];
    
    [[[[self.firebase childByAppendingPath:@"users"] childByAppendingPath:[self.firebase authData].uid] childByAppendingPath:@"friends"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
      
        [self.confirmedFriends removeAllObjects];
        if (snapshot.exists) {
            for (FDataSnapshot *child in snapshot.children) {
                if (child.exists) {
                    NSString *fbid = [child.key substringFromIndex:[@"facebook:" length]];
                    Friend *f = [Friend friendWithFacebookId:fbid];
                    if (f != nil) {
                        [self.confirmedFriends addObject:f];
                    }
                }
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadMainTable" object:nil];
        [self reloadFriendListeners];
    }];
    
    
    [[[[self.firebase childByAppendingPath:@"users"] childByAppendingPath:[self.firebase authData].uid] childByAppendingPath:@"location_requests"] observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (snapshot.exists) {
            for (FDataSnapshot *child in snapshot.children) {
                if (child.exists) {
                    NSLog(@"Request: %@", child);
                    NSString *uid = child.value;
                    NSString *fbid = [uid substringFromIndex:[@"facebook:" length]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationRequest" object:nil userInfo:@{@"from" : fbid, @"id" : child.key}];
                }
            }
        }
        
        NSLog(@"[API] Got location request!");
    }];
}

- (void)reloadFriendListeners {
    
    /* Remove all handles */
    for (NSNumber *number in self.friendHandles) {
        FirebaseHandle handle = (FirebaseHandle) [number unsignedLongValue];
        [[self firebase] removeObserverWithHandle:handle];
    }
    
    [self.friendHandles removeAllObjects];
    NSLog(@"Reloading friend handles..");
    for (Friend *f in self.confirmedFriends) {
        NSLog(@"Subscribing to friend: %@", f.name);
        
        NSString *uid = [NSString stringWithFormat:@"facebook:%@", f.fbid];
        
        // start listening to this friend
        Firebase *checkins = [[[[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"friends"] childByAppendingPath:[self.firebase authData].uid] childByAppendingPath:@"shared_checkins"];
        
        FirebaseHandle handle = [checkins observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            if (snapshot.exists) {
                for (FDataSnapshot *child in snapshot.children) {
                    
                    NSString *checkinId = [child key];
                    
                    // Resolve this to the actual checkin.
                    [[[[[self.firebase childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"checkins"] childByAppendingPath:checkinId] observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                        
                        PersistentCheckin *checkin = [PersistentCheckin fromSnapshot:snapshot ofFriend:f];
                        if (checkin != nil) {
                            NSMutableArray *remove = [NSMutableArray array];
                            for (PersistentCheckin *checkin in self.checkins) {
                                if (checkin.user != nil && [checkin.user.fbid isEqualToString:f.fbid]) {
                                    [remove addObject:checkin];
                                }
                            }
                            [self.checkins removeObjectsInArray:remove];
                            [self.checkins addObject:checkin];
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadCheckins" object:nil];
                        }
                    }];
                }
            }
        } withCancelBlock:^(NSError *error) {
            NSLog(@"[Subscribe] %@", error);
        }];
        
        [self.friendHandles addObject:[NSNumber numberWithUnsignedLong:handle]];
    }
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
                [[API sharedAPI] parseFriends:newFriends];
                if (block != nil) {
                    [self save];
                    block(self.friends, nil);
                }
                NSLog(@"Got facebook friends (%d)", self.friends != nil ? self.friends.count : -1);
            } else {
                NSLog(@"No friends from Facebook.");
            }
            
        } else {
            // Error
            if ([error code] == FBSDKGraphRequestGraphAPIErrorCode) {
                NSLog(@"Experienced an error with the graph api.");
                NSLog(@"%@", [[error userInfo] objectForKey:FBSDKGraphRequestErrorParsedJSONResponseKey]);
                if (block != nil) {
                    block([NSArray array], error);
                }
            }
            
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
}

- (BOOL)isLoggedIn {
    return [FBSDKAccessToken currentAccessToken] != nil && [FBSDKAccessToken currentAccessToken].expirationDate.timeIntervalSince1970 > [NSDate date].timeIntervalSince1970 && [self.firebase authData] != nil;
}

/* Checks into a place. */
- (void)checkinToPlace:(NSString *)place atLongitude:(float)longitude atLatitude:(float)latitude withBlock:(void(^)(NSError *error))block {
    
    // TODO: Send a request to the server to share your location
    if (block != nil) {
        block(nil);
    }
}

- (void)updateLocation:(NSString *)location area:(NSString *)area lon:(CGFloat)lon lat:(CGFloat)lat {
    [self.this_user setLastLocation:CGPointMake(lon, lat) place:location area:area];
}

/* Sends a push indicating the location to the other user */
- (void)shareLocationWithUser:(Friend *)user completion:(void (^)(BOOL succes, NSError *error))completionHandler {
    
    CGFloat lon = [self.this_user lastLongitude];
    CGFloat lat = [self.this_user lastLatitude];
    
    NSString *uid = [[self firebase].authData uid];
    
    Firebase *checkins = [[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"checkins"];
    
    const int timestamp = [[NSDate date] timeIntervalSince1970];
    
    NSString *toId = [NSString stringWithFormat:@"facebook:%@", user.fbid];
    
    NSDictionary *targets = @{toId : [NSNumber numberWithBool:true]};
    
    NSDictionary *checkinData = @{@"timestamp" : [NSNumber numberWithInt:timestamp],
                                  @"lon" : [NSNumber numberWithFloat:lon],
                                  @"lat" : [NSNumber numberWithFloat:lat],
                                  @"area" : [self.this_user lastKnownArea],
                                  @"location" : [self.this_user lastKnownLocation],
                                  @"target" : targets};
    
    [[checkins childByAutoId] updateChildValues:checkinData withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        // Alert your friend of this checkin.
        [[[[[[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"friends"] childByAppendingPath:toId] childByAppendingPath:@"shared_checkins"] childByAppendingPath:[ref key]] setValue:[NSNumber numberWithBool:true] withCompletionBlock:^(NSError *error, Firebase *ref) {
            completionHandler(error == nil, error);
            
            if (error == nil) {
                [PushMaster sendAcknowledgePushToUser:user completion:nil];
            }
        }];
    }];
}



- (void)shareLocationWithUsers:(NSMutableSet *)users completion:(void (^)(BOOL, NSError*))completionHandler emoji:(NSString *)emoji {
    if ([users count] == 0) {
        completionHandler(YES, nil);
    }
    
    /* create checkin */
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self createCheckinAsync:^(NSString *checkinId, NSError *error) {
            if (checkinId) {
                NSLog(@"[API] Created checkin: %@", checkinId);
                completionHandler(YES, nil);
            } else {
                NSLog(@"[API] Checkin failed: %@", error);
                completionHandler(NO, error);
            }
        } targets:[users allObjects] message:emoji];
    });
}


/**
  * Creates a checkin for the specified people, asynchronously.
  * 
  * handler - Handler to invoke when this is all said and done.
  * targetIds - Firebase auth ids OR facebook ids of people who should be able to view this.
  * message - The message associated with the checkin. nullable.
  */
- (void)createCheckinAsync:(void (^) (NSString *checkinId, NSError *error))handler targets:(NSArray *)targetIds message:(NSString * _Nullable)message {
    
    NSString *uid = [[self firebase].authData uid];
    Firebase *checkins = [[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"checkins"];
    
    const int timestamp = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray *trueIds = [NSMutableArray array];
    NSMutableArray *trueObjects = [NSMutableArray array];
    [targetIds enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [trueObjects addObject:[NSNumber numberWithBool:YES]];
        
        if (![obj hasPrefix:@"facebook:"]) {
            obj = [NSString stringWithFormat:@"facebook:%@", obj];
        }
        
        [trueIds addObject:obj];
    }];
    
    NSDictionary *targets = [NSDictionary dictionaryWithObjects:trueObjects forKeys:targetIds];
    
    float lat, lon;
    lat = [[API sharedAPI] this_user].lastLatitude;
    lon = [[API sharedAPI] this_user].lastLongitude;
    
    NSDictionary *checkinData = @{@"timestamp" : [NSNumber numberWithInt:timestamp],
                                  @"lon" : [NSNumber numberWithFloat:lon],
                                  @"lat" : [NSNumber numberWithFloat:lat],
                                  @"area" : [self.this_user lastKnownArea],
                                  @"message" : message == nil ? @"" : message,
                                  @"location" : [self.this_user lastKnownLocation],
                                  @"target" : targets};
    
    [[checkins childByAutoId] updateChildValues:checkinData withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error) {
            /* Couldn't create checkin. */
            NSLog(@"[API] Couldn't create checkin.");
            handler(nil, error);
            return;
        }
        
        /* Alert your friends of this checkin. */
        
        pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
        __block int remaining = (int) [targetIds count];
        __block NSError *real_error;
        
        for (NSString *friendId in trueIds) {
        /* Start a bunch of these things */
            Firebase *fb = [[[[[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"friends"] childByAppendingPath:friendId] childByAppendingPath:@"shared_checkins"] childByAppendingPath:[ref key]];
            
            [fb setValue:[NSNumber numberWithBool:true] withCompletionBlock:^(NSError *error, Firebase *refTwo) {
                
                pthread_mutex_lock(&mutex);
                    remaining--;
                    if (real_error != nil) {
                        /* someone else had an error -- bail */
                        [refTwo removeValue];
                    }
                
                    if (error != nil) {
                        /* this particular transaction failed. */
                        real_error = error;
                    }
                
                    if (remaining == 0) {
                        /* last thread to finish! */
                        if (real_error != nil) {
                            /* someone else had an error -- delete the entire checkin. */
                            [ref removeValue];
                            handler(nil, error);
                        } else {
                            /* no error, all clear! */
                            handler([ref key], nil);
                        }
                    }
                pthread_mutex_unlock(&mutex);
                
                if (error == nil) {
                    [PushMaster sendAcknowledgePushToUser:[Friend friendWithFacebookId:[friendId substringFromIndex:[@"facebook:" length]]] completion:nil];
                }
                
            }];
            
        }
        
        
        
    }];
    
    
}









- (void)removeLocationFromUsers:(NSMutableArray *)users completionHandler:(void (^)())completionHandler {
    
    // TODO: Invalidate our location from users.
}


- (void)sendMessageToUser:(Friend *)user content:(NSString *)text completionHandler:(void (^)())completionHandler {
    
    // TODO: Send a message to one of our users.
}


- (void)loginWithFacebookToFirebase {
    [self.firebase authWithOAuthProvider:@"facebook" token:[FBSDKAccessToken currentAccessToken].tokenString
                     withCompletionBlock:^(NSError *error, FAuthData *authData) {
                         
                         if (error) {
                             NSLog(@"[API] Login failed. %@", error);
                             return;
                         }
                         
                         // Login!
                         [[[[self.firebase childByAppendingPath:@"users"] childByAppendingPath:authData.uid] childByAppendingPath:@"active"] setValue:@"true"];
                         
                         AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
                         
                         // Update our device token if we don't have this
                         if ([delegate deviceToken] != nil) {
                             [[[[self.firebase childByAppendingPath:@"users"] childByAppendingPath:authData.uid] childByAppendingPath:@"push_token"] setValue:delegate.deviceToken];
                         }
                         
                         NSLog(@"[API] Logged in! %@", authData);
                         [self loadExtendedUserInfoFromFacebook];
                     }];
}

- (void)loginFromViewController:(UIViewController *)vc {
    
    /* See if our sdk access token is still valid */
    FBSDKAccessToken *token = [FBSDKAccessToken currentAccessToken];
    if (token != nil) {
        if (token.expirationDate.timeIntervalSince1970 < [[NSDate date] timeIntervalSince1970]) {
            [self loginWithFacebookToFirebase];
        } else {
            // Token expired
            NSLog(@"Facebook: Token expired.");
        }
    }
    
    FBSDKLoginManager *facebookLogin = [[FBSDKLoginManager alloc] init];
    [facebookLogin logInWithReadPermissions:@[@"email", @"user_friends"] fromViewController:vc handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
            NSLog(@"[API] Facebook login failed. Error: %@", error);
        } else if (result.isCancelled) {
            NSLog(@"[API] Facebook login got cancelled.");
        } else {
            [self loginWithFacebookToFirebase];
        }
    }];
}

- (void)parseFriends:(NSArray *)f {
    NSMutableArray *newFriends = [NSMutableArray array];
    for (NSDictionary *dict in f) {
        Friend *friend = [[Friend alloc] initWithFacebookDict:dict];
        [newFriends addObject:friend];
        // If this ends up being set to YES, we updated an existing friend.
        BOOL contains = NO;
        
        for (Friend *f in self.friends) {
            if ([[f  fbid] isEqualToString:[friend fbid]]) {
                [f setName:[friend name]];
                contains = YES;
                break;
            }
        }
        
        if (!contains) {
            [self.friends addObject:friend];
        }
    }
    
    NSMutableArray *toRemove = [NSMutableArray array];
    
    for (Friend *f in self.friends) {
        BOOL shouldRemove = YES;
        for (Friend *f_2 in newFriends) {
            if ([[f_2 fbid] isEqualToString:[f fbid]]){
                shouldRemove = NO;
            }
        }
        if (shouldRemove) {
            [toRemove addObject:f];
        }
    }
    
    [self.friends removeObjectsInArray:toRemove];
}

- (void)getLocationAndAreaWithBlock:(void (^)(BOOL success))completion {
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    Friend *me = [[API sharedAPI] this_user];
    
    const NSString *client_id = @"EGO1P4OIQGZS0EQZ5KIIW55OV3EEN03RCMHSBHU0GUVQZ345";
    const NSString *client_sec = @"E3LEBSPKBUYCFAWH0KTDH0XIEGA0LD01XJBRCR5UKIH2ZR4P";
    const int radius = 400;
    
    NSString *venueURL = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%.9f,%.9f&limit=5&intent=checkin&radius=%d&client_id=%@&client_secret=%@&v=20151203&m=foursquare", [me lastLatitude], [me lastLongitude], radius, client_id, client_sec];
    
    NSURLSession *session =
    [NSURLSession sessionWithConfiguration:sessionConfig
                                  delegate:self
                             delegateQueue:nil];
    
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:venueURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (data != nil) {
            NSError *e;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:0 error:&e];
            
            if (response != nil) {
                NSMutableArray *venues = [NSMutableArray arrayWithArray:(NSArray *)[(NSDictionary *)[response objectForKey:@"response"] objectForKey:@"venues"]];
                
                if (venues != nil && [venues count] == 0) {
                    // Nothing returned
                    NSString *description = @"Somewhere?";
                    NSString *location = @"Couldn't get location.";
                    [[[API sharedAPI] this_user] setLastKnownArea:description];
                    [[[API sharedAPI] this_user] setLastKnownLocation:location];
                    completion(false);
                    return;
                }
                
                NSDictionary *bestVenue = [venues objectAtIndex:0];
                float minDistance = -1;
                for (NSDictionary *venue in venues) {
                    float distance = [[[venue objectForKey:@"location"] objectForKey:@"distance"] floatValue];
                    if (minDistance == -1 || distance < minDistance) {
                        minDistance = distance;
                        bestVenue = venue;
                    }
                }
                
                // Remove the best venue
                [[[API sharedAPI] locationChoices] removeAllObjects];
                
                // Add all the other venues
                for (NSDictionary *venue in venues) {
                    if (venue != nil) {
                        [[[API sharedAPI] locationChoices] addObject:venue];
                    }
                }
                
                [[[API sharedAPI] locationChoices] sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                    NSDictionary *venueOne = (NSDictionary *)obj1;
                    NSDictionary *venueTwo = (NSDictionary *)obj2;
                    
                    return [venueTwo[@"stats"][@"checkinsCount"] compare:venueOne[@"stats"][@"checkinsCount"]];
                }];
                
                NSString *description;
                NSString *location;
                
                if (bestVenue == nil) {
                    description = @"Somewhere?";
                    location = @"Couldn't get location.";
                } else {
                    location = [bestVenue objectForKey:@"name"];
                    NSDictionary *location_dict = [bestVenue objectForKey:@"location"];
                    
                    if ([location_dict objectForKey:@"city"] != nil) {
                        description = [NSString stringWithFormat:@"%@, %@", [location_dict objectForKey:@"city"], [location_dict objectForKey:@"state"]];
                    } else {
                        description = [NSString stringWithFormat:@"%@", [location_dict objectForKey:@"state"]];
                    }
                }
                
                NSLog(@"[API] Setting area, location %@ %@", description, location);
                
                [[[API sharedAPI] this_user] setLastKnownArea:description];
                [[[API sharedAPI] this_user] setLastKnownLocation:location];
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(NO);
                });
            }
            
            return;
        }
        
        completion(NO);
    }];
    [dataTask resume];
    
}


- (void)initParse {
    
    
}

- (void)requestWhereAt:(Friend *)other completion:(void (^)())completion {
    // Place the request in the database
    FQuery *query = [[[[[API sharedAPI] firebase] childByAppendingPath:@"fbids"] queryOrderedByKey] queryEqualToValue:other.fbid];
    
    [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        FDataSnapshot *result = snapshot.children.nextObject;
        
        [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[result value]] childByAppendingPath:@"location_requests"] childByAutoId] setValue:[[API sharedAPI] firebase].authData.uid];
        
        
        [PushMaster sendLocationRequestPushToUser:other completion:^(BOOL sent, NSError *error) {
            if (sent) {
                NSLog(@"Sent location request push!");
            } else {
                NSLog(@"Failed to send push: %@", error);
            }
        }];
        
        completion();
    }];
}

- (void)setLoggedInUser:(NSString *)name token:(NSString *)token {
    NSLog(@"[API] Setting logged in user: %@ %@", name, token);
    [self.this_user setName:name];
    [self.this_user setFbid:token];
}

- (void)handlePush:(NSDictionary *)push {
    
    NSString *request = [push objectForKey:@"request"];
    
    // TODO: this is idioticly unoptimized
    if ([@"location" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationRequest" object:nil userInfo:push];
    } else if ([@"forget" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ForgetRequest" object:nil userInfo:push];
    } else if ([@"acknowledge" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AcknowledgeRequest" object:nil userInfo:push];
    } else if ([@"message" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MessageReceived" object:nil userInfo:push];
    }
}

- (Friend *)currentUser {
    return self.this_user;
}


static API *sharedAPI = nil;

+ (instancetype)sharedAPI {
    if (sharedAPI == nil) {
        NSLog(@"[API] Initializing API..........");
        sharedAPI = [[API alloc] init];
    }
    
    return sharedAPI;
}

- (void)dealloc {
    if (manager) {
        manager.delegate = nil;
        [manager stopUpdatingLocation];
    }
    
    [self save];
}

- (void)save {
    if (self.this_user) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.this_user] forKey:@"this_user"];
        NSLog(@"[API] Saving current user...");
    }
    if (self.friends) {
        NSLog(@"[API] Saving friends...");
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.friends] forKey:@"friends"];
    }
    /*if (self.checkins) {
        NSLog(@"[API] Saving checkins...");
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.checkins] forKey:@"checkins"];
    }*/
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"[API] Got location.");
    CLLocation *first = [locations lastObject];
    
    if (first.horizontalAccuracy < 0) {
        NSLog(@"[API] Location was inaccurate. Ignoring.");
        return;
    }
    
    checkinAvailable = YES;
    
    float oldLong = [self.this_user lastLongitude];
    float oldLat = [self.this_user lastLatitude];
    
    [[[API sharedAPI] this_user] setLastLatitude:[first coordinate].latitude];
    [[[API sharedAPI] this_user] setLastLongitude:[first coordinate].longitude];
    
    NSLog(@"[API] Location available! %f, %f", [first coordinate].latitude, [first coordinate].longitude);
    if (oldLat == 0 && oldLong == 0) {
        // This is our first update
        NSLog(@"[API] First location!");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationAvailable" object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NewLocationAvailable" object:nil];
    
    [self getLocationAndAreaWithBlock:^ (BOOL success){
        NSLog(@"[API] Loaded initial location: location=%@, area=%@", self.this_user.lastKnownLocation, self.this_user.lastKnownArea);
    }];
}

- (BOOL)hasLocation {
    return checkinAvailable;
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    UIAlertView *errorAlert = [[UIAlertView alloc]initWithTitle:@"Error" message:@"Please enable locations -- really, what did you expect this app to do without location services?" delegate:nil cancelButtonTitle:@"Sure, I guess." otherButtonTitles: nil];
    
    [errorAlert show];
    NSLog(@"Error: %@",error.description);
    
}

- (void)initLocations {
    
    NSLog(@"[API] Location services enabled?: %d", [CLLocationManager locationServicesEnabled]);
    
    // Create the location manager if this object does not
    // already have one.
    if (nil == manager) {
        manager = [[CLLocationManager alloc] init];
    }
    
    manager.delegate = self;
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    // Set a movement threshold for new events.
    manager.distanceFilter = 100; // meters
    
    if ([manager respondsToSelector:@selector(requestAlwaysAuthorization)]){
        [manager requestAlwaysAuthorization];
    }
    
    /*for (PersistentCheckin *checkin in self.checkins) {
        [manager startMonitoringForRegion:[checkin region]];
    }*/
    
    [manager startUpdatingLocation];
}

- (void)startMonitoringRegion:(CLRegion *)region withLocationName:(NSString *)name area:(NSString *)area friends:(NSSet *)_friends {
    /*PersistentCheckin *checkin = [[PersistentCheckin alloc] initWithRegion:region location:name name:area friends:_friends];
    [self.checkins addObject:checkin];
    if (manager != nil) {
        [manager startMonitoringForRegion:region];
    }
    [checkin markActive];*/
}

- (void)loadExtendedUserInfoFromFacebook {
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"name, email"}];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            [[API sharedAPI] setLoggedInUser:result[@"name"] token:result[@"id"]];
            
            // Mark this user as active / set facebook id.
            Firebase *user = [[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[API sharedAPI].firebase.authData.uid];
            [[user childByAppendingPath:@"active"] setValue:[NSNumber numberWithBool:YES]];
            [[user childByAppendingPath:@"fbid"] setValue:result[@"id"]];
            [[user childByAppendingPath:@"name"] setValue:result[@"name"]];
            
            // Update our global table of fbid -> user ids
            Firebase *fbid = [[[[API sharedAPI] firebase] childByAppendingPath:@"fbids"] childByAppendingPath:result[@"id"]];
            [fbid setValue:[user authData].uid];
            [self setupListeners];
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager
didStartMonitoringForRegion:(CLRegion *)region {
    CLCircularRegion *circle = (CLCircularRegion *)region;
    NSLog(@"[API] Successfully started monitoring checkin!: %f, %f", [circle center].latitude, [circle center].longitude);
    [self save];
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(CLRegion *)region
              withError:(NSError *)error {
    NSLog(@"[API] Couldn't monitor checkin - %@ - Removing..", [error localizedFailureReason]);
    for (PersistentCheckin *checkin in self.checkins) {
        if ([[checkin region] isEqual:region]) {
            // remove
            [self.checkins removeObject:checkin];
            break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    NSLog(@"[API] [Location] Entered region!");
    PersistentCheckin *current = nil;
    for (PersistentCheckin *checkin in self.checkins) {
        if ([[checkin region] isEqual:region]) {
            current = checkin;
            break;
        }
    }
    
    if (current != nil) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        [notification setAlertTitle:[NSString stringWithFormat:@"Checkin: %@!", [current location]]];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setFireDate:[NSDate date]];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        //[self shareLocationWithUsers:[current friends] completion:nil];
    }
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region {
    NSLog(@"[API] [Location] Exited region!");
    
    PersistentCheckin *current = nil;
    for (PersistentCheckin *checkin in self.checkins) {
        if ([[checkin region] isEqual:region]) {
            current = checkin;
            break;
        }
    }
    
    if (current != nil) {
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        [notification setAlertTitle:[NSString stringWithFormat:@"Checkout: %@!", [current location]]];
        [notification setSoundName:UILocalNotificationDefaultSoundName];
        [notification setFireDate:[NSDate date]];
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        [self removeLocationFromUsers:[current friends] completionHandler:nil];
    }
}

@end
