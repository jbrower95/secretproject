//
//  FriendLocationController.h
//  Flawk
//
//  Created by Justin Brower on 12/3/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Friend.h"

@interface FriendLocationController : UIViewController {
    IBOutlet MKMapView *map;
    Friend *person;
}

@property (nonatomic, retain) IBOutlet MKMapView *map;
@property (nonatomic, retain) Friend *person;
@end
