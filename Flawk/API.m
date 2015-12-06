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
    
    self.this_user = [[Friend alloc] init];
    self.friends = [[NSMutableArray alloc] init];
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

- (void)updateLocation:(NSString *)location area:(NSString *)area lon:(CGFloat)lon lat:(CGFloat)lat {
    [self.this_user setLastLocation:CGPointMake(lon, lat) place:location area:area];
}

/* Sends a push indicating the location to the other user */
- (void)shareLocationWithUser:(Friend *)user {
    
    CGFloat lon = [self.this_user lastLongitude];
    CGFloat lat = [self.this_user lastLatitude];
    
    PFPush *push = [PFPush push];
    
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"facebookId" equalTo:[user fbid]];
    
    NSString *message = [NSString stringWithFormat:@"%@ shared their location!", [[[API sharedAPI] this_user] name]];
    
    NSDictionary *data = @{@"request" : @"acknowledge", @"location" : [self.this_user lastKnownLocation], @"area" : [self.this_user lastKnownArea], @"lon" : [NSString stringWithFormat:@"%f", lon], @"lat" : [NSString stringWithFormat:@"%f", lat], @"from" : self.this_user.fbid, @"alert" : message, @"sound" : @"default"};
    
    [push setQuery:query];
    [push setData:data];
    
    // Send push.
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"[API] Successfully shared location!");
        } else {
            NSLog(@"[API] Failed to share location: %@", [error localizedFailureReason]);
        }
    }];
}

- (void)sendMessageToUser:(Friend *)user content:(NSString *)text completionHandler:(void (^)())completionHandler {
    
    PFPush *push = [PFPush push];
    
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"facebookId" equalTo:[user fbid]];
    
    NSDictionary *data = @{@"request" : @"message", @"from" : self.this_user.fbid, @"sound" : @"default", @"text" : text, @"alert" : [NSString stringWithFormat:@"%@: %@", [[[API sharedAPI] this_user] name], text]};
    [push setData:data];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (!succeeded) {
            NSLog(@"[API] Couldn't send message in background.");
        }
        completionHandler();
    }];
    
}


/* Sends a push indicating the location to the other user */
- (void)shareLocationWithUser:(Friend *)user completion:(void (^)(void))completionHandler {
    
    CGFloat lon = [self.this_user lastLongitude];
    CGFloat lat = [self.this_user lastLatitude];
    
    PFPush *push = [PFPush push];
    
    PFQuery *query = [PFInstallation query];
    [query whereKey:@"facebookId" equalTo:[user fbid]];
    
    NSDictionary *data = @{@"request" : @"acknowledge", @"location" : [self.this_user lastKnownLocation], @"area" : [self.this_user lastKnownArea], @"lon" : [NSString stringWithFormat:@"%f", lon], @"lat" : [NSString stringWithFormat:@"%f", lat], @"from" : self.this_user.fbid, @"sound" : @"default"};
    
    [push setQuery:query];
    [push setData:data];
    
    // Send push.
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"[API] Successfully shared location!");
        } else {
            NSLog(@"[API] Failed to share location: %@", [error localizedFailureReason]);
        }
        completionHandler();
    }];
}


- (void)refreshFacebookLogin {
    [FBSDKAccessToken refreshCurrentAccessToken:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        
        if (error != nil) {
            NSLog(@"[API] Critical -- Could not refresh Facebook login.");
            [[NSNotificationCenter defaultCenter] postNotificationName:API_REFRESH_FAILED_EVENT object:self];
        } else {
            // Success -- tell no one anything.
            FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"name, email"}];
            
            [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                
                if (!error) {
                    NSLog(@"fetched user:%@  and Email : %@", result,result[@"email"]);
                    
                    NSLog(@"[API] Refreshed token successfully.");
                    [[API sharedAPI] setLoggedInUser:result[@"name"] token:[[FBSDKAccessToken currentAccessToken] userID]];
                    
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [[NSNotificationCenter defaultCenter] postNotificationName:API_REFRESH_SUCCESS_EVENT object:self];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^() {
                        [[NSNotificationCenter defaultCenter] postNotificationName:API_REFRESH_FAILED_EVENT object:self];
                    });
                }
            }];
            
            
        }
        
    }];
}

- (void)parseFriends:(NSArray *)f {
    [self.friends removeAllObjects];
    for (NSDictionary *dict in f) {
        Friend *friend = [[Friend alloc] initWithFacebookDict:dict];
        [self.friends addObject:friend];
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
    
    NSString *message = [NSString stringWithFormat:@"%@: where you @?", [self.this_user name]];
    [push setData:@{@"request" : @"location", @"from" : [self.this_user fbid], @"alert" : message, @"category" : @"REQUEST_LOCATION_CATEGORY", @"sound" : @"default"}];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (!succeeded) {
            NSLog(@"[API] Error: Didn't succeed sending push - %@", [error localizedDescription]);
        } else {
            NSLog(@"[API] Sent request for location! %@", [error localizedDescription]);
        }
    }];
}

- (void)setLoggedInUser:(NSString *)name token:(NSString *)token {
    NSLog(@"[API] Setting logged in user: %@ %@", name, token);
    [self.this_user setName:name];
    [self.this_user setFbid:token];
}

- (void)handlePush:(NSDictionary *)push {
    
    NSString *request = [push objectForKey:@"request"];
    
    if ([@"location" isEqualToString:request]) {
        // We're going to present an action controller.
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LocationRequest" object:nil userInfo:push];
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

+ (id)sharedAPI {
    if (sharedAPI == nil) {
        NSLog(@"[API] Initializing API..........");
        sharedAPI = [[API alloc] init];
        NSData *encodedObject = [[NSUserDefaults standardUserDefaults] objectForKey:@"current_user"];
        if (encodedObject != nil) {
            sharedAPI.this_user = (Friend *)[NSKeyedUnarchiver unarchiveObjectWithData:encodedObject];
        }
    }
    
    return sharedAPI;
}

- (void)dealloc {
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:self.this_user] forKey:@"current_user"];
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

@end
