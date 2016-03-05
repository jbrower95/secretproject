//
//  LocationDaemon.m
//  Flawk
//
//  Created by Justin Brower on 12/20/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "LocationDaemon.h"
#import "PersistentCheckin.h"
#import "API.h"

@implementation LocationDaemon


- (id)init {
    
    if (self = [super init]) {
        
        manager = [[CLLocationManager alloc] init];
        
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
        
        for (PersistentCheckin *checkin in [[API sharedAPI] checkins]) {
            [manager startMonitoringForRegion:[checkin region]];
        }
        
        [manager startUpdatingLocation];
    }
    
    return self;
}

@end
