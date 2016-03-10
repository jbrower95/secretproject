//
//  LocationCell.m
//  Flawk
//
//  Created by Justin Brower on 3/9/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "LocationCell.h"
#import "UIImageView+Web.h"

@implementation LocationCell

@synthesize nameLabel, locationLabel, distanceLabel, iconView;

- (void)applyLocation:(NSDictionary *)venue {
    
    NSDictionary *location = venue[@"location"];
    
    NSString *location_str;
    
    if (location[@"city"] != nil && location[@"state"] != nil) {
        location_str = [NSString stringWithFormat:@"%@, %@", location[@"city"], location[@"state"]];
    } else if (location[@"state"] != nil) {
        location_str = location[@"state"];
    } else if (location[@"country"] != nil) {
        location_str = location[@"country"];
    } else {
        location_str = @"Somewhere";
    }
    
    NSString *name_str = venue[@"name"];
    
    [self.locationLabel setText:location_str];
    [self.nameLabel setText:name_str];
    
    NSDictionary *icon = venue[@"categories"][0][@"icon"];
    
    NSString *iconImageUrl = [NSString stringWithFormat:@"%@bg_100%@", icon[@"prefix"], icon[@"suffix"]];
    [self.iconView loadRemoteUrl:iconImageUrl];
    [self.distanceLabel setText:[NSString stringWithFormat:@"%d", [venue[@"stats"][@"checkinsCount"] intValue]]];
}

@end
