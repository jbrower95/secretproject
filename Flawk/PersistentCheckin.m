//
//  Checkin.m
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "PersistentCheckin.h"
#import "API.h"

@implementation PersistentCheckin

@synthesize name, region, location, friends;

- (id)initWithRegion:(CLRegion *)_region location:(NSString *)_location name:(NSString *)_name friends:(NSMutableArray *)_friends {
    if (self = [super init]) {
        self.name = _name;
        self.region = _region;
        self.location = _location;
        self.friends = _friends;
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    //Encode properties, other class variables, etc
    [encoder encodeObject:name forKey:@"name"];
    [encoder encodeObject:region forKey:@"region"];
    [encoder encodeObject:location forKey:@"location"];
    [encoder encodeObject:friends forKey:@"friends"];
}

- (id)initWithCoder:(NSCoder *)decoder {
    if((self = [super init])) {
        //decode properties, other class vars
        name = [decoder decodeObjectForKey:@"name"];
        region = [decoder decodeObjectForKey:@"region"];
        location = [decoder decodeObjectForKey:@"location"];
        friends = [decoder decodeObjectForKey:@"lon"];
    }
    return self;
}

- (void)markActive {
    
    // Create a checkin for the current user.
    const double lat = [[API sharedAPI] this_user].lastLatitude;
    const double lon = [[API sharedAPI] this_user].lastLongitude;
}

@end
