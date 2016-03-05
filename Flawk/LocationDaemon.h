//
//  LocationDaemon.h
//  Flawk
//
//  This handles all of the location services stuff and also
//
//
//  Created by Justin Brower on 12/20/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface LocationDaemon : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *manager;
}

@end
