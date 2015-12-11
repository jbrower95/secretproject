//
//  Checkin.m
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "PersistentCheckin.h"

@implementation PersistentCheckin

@synthesize name, region, location;

- (id)initWithRegion:(CLRegion *)_region location:(NSString *)_location name:(NSString *)_name friends:(NSMutableArray *)friends {
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

@end
