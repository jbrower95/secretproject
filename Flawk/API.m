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

NSString *const API_REFRESH_FAILED_EVENT = @"APIRefreshFailedEvent";
NSString *const API_REFRESH_SUCCESS_EVENT = @"APIRefreshSuccessEvent";
NSString *const API_RECEIVED_FRIEND_REQUEST_EVENT = @"APIReceivedFriendRequestEvent";

NSString *const FIREBASE_URI = @"https://flawkdb.firebaseio.com";

@implementation API

@synthesize manager; 

@synthesize friends, this_user, checkins, firebase, outstandingFriendRequests, sentFriendRequests, confirmedFriends, friendHandles;

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
    }

    NSData *friendsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"friends"];
    
    if (friendsData != nil) {
        NSLog(@"[API] Reloading saved friends...");
        self.friends = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithData:friendsData];
    } else {
        NSLog(@"[API] Couldn't reload friends.");
    }
    
    NSData *checkinsData = [[NSUserDefaults standardUserDefaults] objectForKey:@"checkins"];
    if (checkinsData != nil) {
        self.checkins = (NSMutableArray *)[NSKeyedUnarchiver unarchiveObjectWithData:checkinsData];
        NSLog(@"[API] Reloaded %lu checkins.", [self.checkins count]);
    } else {
        NSLog(@"[API] Couldn't reload checkins.");
    }
    
    NSData *userData = [[NSUserDefaults standardUserDefaults] objectForKey:@"this_user"];
    
    if (userData != nil) {
        self.this_user = (Friend *)[NSKeyedUnarchiver unarchiveObjectWithData:userData];
    }
    
    
    return self;
}

- (void)setupListeners {
    FQuery *query = [[[self.firebase childByAppendingPath:@"requests"] queryOrderedByChild:@"to"] queryEqualToValue:[self this_user].fbid];
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
    
    for (Friend *f in self.confirmedFriends) {
        
        
        // start listening to this friend
        Firebase *checkins = [[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:[NSString stringWithFormat:@"facebook:%@", f.fbid]] childByAppendingPath:@"checkins"];
        
        FirebaseHandle handle = [checkins observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
            PersistentCheckin *checkin = [PersistentCheckin fromSnapshot:snapshot ofFriend:f];
            if (checkin != nil) {
                
                if ([self.checkins containsObject:checkin]) {
                    [self.checkins removeObject:checkin];
                }
                
                [self.checkins addObject:checkin];
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadCheckins" object:nil];
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
                NSLog(@"Parsing friends.");
                [[API sharedAPI] parseFriends:newFriends];
                if (block != nil) {
                    [self save];
                    block(self.friends, nil);
                }
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
    return [FBSDKAccessToken currentAccessToken] != nil && [self.firebase authData] != nil;
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
    
    // TODO: Share our location with the user:
    
    [self getLocationAndAreaWithBlock:^{
       
        NSString *uid = [[self firebase].authData uid];
        
        Firebase *checkins = [[[[self firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"checkins"];
        
        const int timestamp = [[NSDate date] timeIntervalSince1970];
        
        NSDictionary *targets = @{[NSString stringWithFormat:@"facebook:%@", user.fbid] : [NSNumber numberWithBool:true]};
        
        NSDictionary *checkinData = @{@"timestamp" : [NSNumber numberWithInt:timestamp],
                                      @"lon" : [NSNumber numberWithFloat:lon],
                                      @"lat" : [NSNumber numberWithFloat:lat],
                                      @"area" : [self.this_user lastKnownArea],
                                      @"location" : [self.this_user lastKnownLocation],
                                      @"target" : targets};
        
        [[checkins childByAutoId] updateChildValues:checkinData withCompletionBlock:^(NSError *error, Firebase *ref) {
            completionHandler(error == nil, error);
        }];
    }];
    
}


- (void)removeLocationFromUsers:(NSMutableArray *)users completionHandler:(void (^)())completionHandler {
    
    // TODO: Invalidate our location from users.
}


- (void)sendMessageToUser:(Friend *)user content:(NSString *)text completionHandler:(void (^)())completionHandler {
    
    // TODO: Send a message to one of our users.
}

- (void)shareLocationWithUsers:(NSMutableSet *)users completion:(void (^)(BOOL, NSError*))completionHandler {
    if ([users count] == 0) {
        completionHandler(YES, nil);
    }
    
    NSString *fbid = [users anyObject];
    [users removeObject:fbid];
    
    Friend *f = [[Friend alloc] initWithName:nil fbId:fbid];
    [self shareLocationWithUser:f completion:^(BOOL success, NSError *error) {
        [self shareLocationWithUsers:users completion:completionHandler];
    }];
}


- (void)login {
    FBSDKLoginManager *facebookLogin = [[FBSDKLoginManager alloc] init];
    [facebookLogin logInWithReadPermissions:@[@"email"]
                                    handler:^(FBSDKLoginManagerLoginResult *facebookResult, NSError *facebookError) {
                                        if (facebookError) {
                                            NSLog(@"[API] Facebook login failed. Error: %@", facebookError);
                                        } else if (facebookResult.isCancelled) {
                                            NSLog(@"[API] Facebook login got cancelled.");
                                        } else {
                                            NSString *accessToken = [[FBSDKAccessToken currentAccessToken] tokenString];
                                            [self.firebase authWithOAuthProvider:@"facebook" token:accessToken
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

- (void)getLocationAndAreaWithBlock:(void (^)())completion {
    
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
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NULL error:&e];
            
            if (response != nil) {
                NSArray *venues = (NSArray *)[(NSDictionary *)[response objectForKey:@"response"] objectForKey:@"venues"];
                
                if (venues != nil && [venues count] == 0) {
                    // Nothing returned
                    NSString *description = @"Somewhere?";
                    NSString *location = @"Couldn't get location.";
                    [[[API sharedAPI] this_user] setLastKnownArea:description];
                    [[[API sharedAPI] this_user] setLastKnownLocation:location];
                    completion();
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
                
                
                NSString *description;
                NSString *location;
                
                if (bestVenue == nil) {
                    description = @"Somewhere?";
                    location = @"Couldn't get location.";
                } else {
                    location = [bestVenue objectForKey:@"name"];
                    NSDictionary *location_dict = [bestVenue objectForKey:@"location"];
                    description = [NSString stringWithFormat:@"%@, %@", [location_dict objectForKey:@"city"], [location_dict objectForKey:@"state"]];
                }
                
                NSLog(@"[API] Setting area, location %@ %@", description, location);
                
                [[[API sharedAPI] this_user] setLastKnownArea:description];
                [[[API sharedAPI] this_user] setLastKnownLocation:location];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
        
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
        
        /*dispatch_async(dispatch_get_main_queue(), ^{
            // Alert this user
            [PushMaster sendLocationRequestPushToUser:other completion:^(BOOL sent, NSError *error) {
                if (sent) {
                    NSLog(@"[API] Sent push notification!");
                } else {
                    NSLog(@"[API] Error - Didn't send push notification (%@)", error);
                }
            }];
            completion();
        });*/
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
    }
    if ([@"forget" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ForgetRequest" object:nil userInfo:push];
    }
    if ([@"acknowledge" isEqualToString:request]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AcknowledgeRequest" object:nil userInfo:push];
    }
    if ([@"message" isEqualToString:request]) {
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
    if (self.checkins) {
        NSLog(@"[API] Saving checkins...");
        [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.checkins] forKey:@"checkins"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    NSLog(@"[API] Updating location.");
    CLLocation *first = [locations lastObject];
    
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
        [self shareLocationWithUsers:[current friends] completion:nil];
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
