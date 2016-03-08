//
//  Friend.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PersistentCheckin.h"

@interface Friend : NSObject<NSCoding> {
    
    /* The full name of this friend. */
    NSString *name;
    
    /* The facebook id of this friend. */
    NSString *fbid;
    
    /* The last known location of this friend, as a string ('Antonio's pizza') */
    NSString *lastKnownLocation;
    
    /* The last known area of this friend, as a string ('Brown University') */
    NSString *lastKnownArea;
    
    /* The profile picture of this person from facebook */
    NSString *profilePictureUrl;
    
    /* The last known latitude of this friend. */
    double lastLatitude;
    
    /* The last known longitude of this friend. */
    double lastlongitude;
    
    /* The timestamp of the last known location. */
    double lastTimestamp;
    
    /* The last checkin associated with this person */
    PersistentCheckin *lastCheckin;
}

- (id)initWithName:(NSString *)name fbId:(NSString *)fbId;
- (id)initWithFacebookDict:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

- (void)loadFacebookProfilePictureUrlWithBlock:(void (^)(NSString *url))completion;

@property (nonatomic, retain) PersistentCheckin *lastCheckin;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *fbid;

@property (nonatomic, retain) NSString *lastKnownLocation;
@property (nonatomic, retain) NSString *lastKnownArea;

@property (nonatomic) double lastLatitude;
@property (nonatomic) double lastLongitude;
@property (nonatomic) double lastTimestamp;

- (CGPoint)getLastLocation;

- (BOOL)locationKnown;
- (NSString *)nickname;
- (void)setLastLocation:(CGPoint)location place:(NSString *)place area:(NSString *)area;

+ (instancetype)friendWithFacebookId:(NSString *)fbid;

@end
