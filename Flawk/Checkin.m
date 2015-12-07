//
//  Checkin.m
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "Checkin.h"

@implementation Checkin

@synthesize name, region, location;

- (id)initWithRegion:(CLRegion *)_region location:(NSString *)_location name:(NSString *)_name friends:(NSSet *)friends {
    if (self = [super init]) {
        self.name = _name;
        self.region = _region;
        self.location = _location;
        self.friends = _friends;
    }
    
    return self;
}

@end
