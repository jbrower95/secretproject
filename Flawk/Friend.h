//
//  Friend.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface Friend : NSObject<NSCoding> {
    
    /* The full name of this friend. */
    NSString *name;
    
    /* The facebook id of this friend. */
    NSString *fbid;
    
    /* The last known location of this friend, as a string ('Antonio's pizza') */
    NSString *lastKnownLocation;
    
    /* The last known area of this friend, as a string ('Brown University') */
    NSString *lastKnownArea;
    
    /* The last known latitude of this friend. */
    double lastLatitude;
    
    /* The last known longitude of this friend. */
    double lastlongitude;
    
    /* The timestamp of the last known location. */
    double lastTimestamp;
    
    /* The */
    PFUser *user;
}

- (id)initWithName:(NSString *)name fbId:(NSString *)fbId;
- (id)initWithFacebookDict:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;
- (id)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *fbid;

@property (nonatomic, retain) NSString *lastKnownLocation;
@property (nonatomic, retain) NSString *lastKnownArea;

@property (nonatomic) double lastLatitude;
@property (nonatomic) double lastLongitude;
@property (nonatomic) double lastTimestamp;

@property (nonatomic, retain) PFUser *user;

- (CGPoint)getLastLocation;

- (BOOL)locationKnown;

- (void)setLastLocation:(CGPoint)location place:(NSString *)place area:(NSString *)area;

- (void)setUser:(PFUser *)user;
@end
