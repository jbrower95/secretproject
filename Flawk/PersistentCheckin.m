//
//  Checkin.m
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "PersistentCheckin.h"
#import "API.h"
#import <CoreLocation/CoreLocation.h>

@implementation PersistentCheckin

@synthesize name, region, location, friends, timestamp, user;

- (id)initWithRegion:(CLRegion *)_region location:(NSString *)_location name:(NSString *)_name friends:(NSMutableArray *)_friends timestamp:(int)_timestamp user:(Friend *)u {
    if (self = [super init]) {
        self.name = _name;
        self.region = _region;
        self.location = _location;
        self.friends = _friends;
        self.timestamp = _timestamp;
        self.user = u;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeObject:region forKey:@"region"];
    [encoder encodeObject:location forKey:@"location"];
    [encoder encodeObject:friends forKey:@"friends"];
    [encoder encodeInt:timestamp forKey:@"timestamp"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        name = [decoder decodeObjectForKey:@"name"];
        region = [decoder decodeObjectForKey:@"region"];
        location = [decoder decodeObjectForKey:@"location"];
        friends = [decoder decodeObjectForKey:@"friends"];
        timestamp = [decoder decodeIntForKey:@"timestamp"];
    }
    return self;
}

+ (instancetype)fromSnapshot:(FDataSnapshot *)snapshot ofFriend:(Friend *)user {
    
    if (!snapshot.exists) {
        return nil;
    }
    
    CLCircularRegion *region = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake([[snapshot childSnapshotForPath:@"lat"].value floatValue], [[snapshot childSnapshotForPath:@"lon"].value floatValue]) radius:1 identifier:user.name];
    
    PersistentCheckin *checkin = [[PersistentCheckin alloc] initWithRegion:region location:[snapshot childSnapshotForPath:@"location"].value name:[snapshot childSnapshotForPath:@"name"].value friends:nil timestamp:[[snapshot childSnapshotForPath:@"timestamp"].value intValue] user:user];
    
    return checkin;
}

- (BOOL)isEqual:(id)object {
    
    if (![object isKindOfClass:[PersistentCheckin class]]){
        return NO;
    }
    
    PersistentCheckin *request = (PersistentCheckin *)object;
    return (request.timestamp == self.timestamp && [[request user].fbid isEqualToString:self.user.fbid]);
}


@end
