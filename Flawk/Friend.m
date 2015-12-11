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

@synthesize name=_name, fbid=_fbId, user, lastLatitude, lastLongitude, lastKnownArea, lastKnownLocation;

- (id)initWithName:(NSString *)fullName fbId:(NSString *)fbId {
    
    if (self = [super init]) {
        _name = fullName;
        _fbId = fbId;
    }
    
    // No valid location data yet.
    lastTimestamp = -1;
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:_name forKey:@"name"];
    [encoder encodeObject:_fbId forKey:@"fbId"];
    [encoder encodeFloat:lastLatitude forKey:@"lat"];
    [encoder encodeFloat:lastlongitude forKey:@"lon"];
    [encoder encodeFloat:lastTimestamp forKey:@"timestamp"];
    [encoder encodeObject:lastKnownArea forKey:@"area"];
    [encoder encodeObject:lastKnownLocation forKey:@"location"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        _name = [decoder decodeObjectForKey:@"name"];
        _fbId = [decoder decodeObjectForKey:@"fbId"];
        lastLatitude = [decoder decodeFloatForKey:@"lat"];
        lastlongitude = [decoder decodeFloatForKey:@"lon"];
        lastKnownArea = [decoder decodeObjectForKey:@"area"];
        lastTimestamp = [decoder decodeFloatForKey:@"timestamp"];
        lastKnownLocation = [decoder decodeObjectForKey:@"location"];
    }
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
    
    return [NSString stringWithString:randomString];
}

/* Returns a CGPoint (lon, lat) of the last known location of this friend. */
- (CGPoint)getLastLocation {
    return CGPointMake(self.lastLongitude, self.lastLatitude);
}

- (BOOL)locationKnown {
    return lastTimestamp != -1;
}

- (NSString *)lastKnownArea {
    if (lastKnownArea == nil) {
        return @"";
    } else {
        return lastKnownArea;
    }
}

- (NSString *)lastKnownLocation {
    if (lastKnownLocation == nil) {
        return @"";
    } else {
        return lastKnownLocation;
    }
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
    [u saveInBackground];
}

@end
