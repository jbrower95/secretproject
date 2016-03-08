//
//  Friend.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "Friend.h"
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import "API.h"

@implementation Friend

@synthesize name=_name, fbid=_fbId, lastLatitude, lastLongitude, lastKnownArea, lastTimestamp, lastKnownLocation;

- (id)initWithName:(NSString *)fullName fbId:(NSString *)fbId {
    
    if (self = [super init]) {
        _name = fullName;
        _fbId = fbId;
    }
    
    // No valid location data yet.
    lastTimestamp = -1;
    
    return self;
}

- (NSString *)nickname {
    if ([self name] == nil) {
        return @"";
    }
    
    NSArray *parts = [[self name] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (parts.count > 0) {
        return parts[0];
    } else {
        return @"Someone";
    }
}

+ (instancetype)friendWithFacebookId:(NSString *)fbid {
    
    for (Friend *friend in [[API sharedAPI] friends]) {
        if ([[friend fbid] isEqualToString:fbid]) {
            return friend;
        }
    }
    
    return nil;
}

- (void)loadFacebookProfilePictureUrlWithBlock:(void (^)(NSString *url))completion {
    
    if (_fbId == nil) {
        completion(nil);
    }
    
    if (profilePictureUrl != nil) {
        completion(profilePictureUrl);
    }
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:[NSString stringWithFormat:@"%@/picture", _fbId] parameters:@{@"redirect" : @"false", @"type" : @"small", @"fields" : @"url"}];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            profilePictureUrl = result[@"data"][@"url"];
            completion(profilePictureUrl);
        } else {
            completion(nil);
        }
    }];
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

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:_name forKey:@"name"];
    [dictionary setObject:_fbId forKey:@"fbId"];
    [dictionary setObject:[NSNumber numberWithFloat:lastLatitude] forKey:@"lat"];
    [dictionary setObject:[NSNumber numberWithFloat:lastlongitude] forKey:@"lon"];
    [dictionary setObject:[NSNumber numberWithFloat:lastTimestamp] forKey:@"timestamp"];
    [dictionary setObject:lastKnownArea forKey:@"area"];
    [dictionary setObject:lastKnownLocation forKey:@"location"];
    return dictionary;
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
    
    return self;
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

@end
