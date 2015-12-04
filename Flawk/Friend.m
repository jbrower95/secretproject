//
//  Friend.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "Friend.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <ParseFacebookUtilsV4/ParseFacebookUtilsV4.h>
#import <Parse/Parse.h>

@implementation Friend

@synthesize name=_name, fbid=_fbId, user;

- (id)initWithName:(NSString *)fullName fbId:(NSString *)fbId {
    
    if (self = [super init]) {
        _name = fullName;
        _fbId = fbId;
    }
    
    // No valid location data yet.
    lastTimestamp = -1;
    
    return self;
}

- (id)initWithFacebookDict:(NSDictionary *)dict {
    if (self = [super init]) {
        _name = [dict objectForKey:@"name"];
        _fbId = [dict objectForKey:@"id"];
    }
    
    // No valid location data yet.
    lastTimestamp = -1;
    [self initializeWithParse];
    
    return self;
}

- (void)initializeWithParse {
    FBSDKAccessToken *accessToken = [FBSDKAccessToken currentAccessToken];
    PFQuery *query = [PFUser query];
    [query whereKey:@"facebookId" equalTo:[accessToken userID]];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject * _Nullable object, NSError * _Nullable error) {
        if (object != nil) {
            NSLog(@"[Friend] Matched friend with parse.");
            [self setUser:(PFUser *)object];
        } 
    }];
}

- (NSString *)getRandomPassword {
    int length = 20;
    
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789!@#$%^&*";

    NSMutableString *randomString = [NSMutableString stringWithCapacity: length];
    
    for (int i=0; i< length; i++) {
        [randomString appendFormat: @"%C", [alphabet characterAtIndex: arc4random_uniform([alphabet length])]];
    }
    
    NSLog(@"Generated random password: %@", randomString);
    
    return [NSString stringWithString:randomString];
}

/* Returns a CGPoint (lon, lat) of the last known location of this friend. */
- (CGPoint)getLastLocation {
    return CGPointMake(self.lastLongitude, self.lastLatitude);
}

- (BOOL)locationKnown {
    return lastTimestamp != -1;
}

/* Sets the last observed location of this friend. Timestamp is inferred from system time. */
- (void)setLastLocation:(CGPoint)location place:(NSString *)place area:(NSString *)area {
    self.lastLongitude = location.x;
    self.lastLatitude = location.y;
    self.lastKnownLocation = place;
    self.lastKnownArea = area;
    lastTimestamp = time(NULL);
}

- (void)setUser:(PFUser *)u {
    [u setObject:_name forKey:@"username"];
    [u setObject:_fbId forKey:@"facebookId"];
    [u saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"[Friend] Updated user in parse!");
        } else {
            NSLog(@"[Friend] Failed to update user in parse.");
        }
    }];
}

@end
