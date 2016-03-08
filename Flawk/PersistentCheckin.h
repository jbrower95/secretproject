//
//  Checkin.h
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <Firebase/Firebase.h>

@class Friend;

@interface PersistentCheckin : NSObject <NSCoding> {
    CLRegion *region;
    NSString *location;
    NSString *name;
    NSMutableArray *friends;
    Friend *user;
    int timestamp;
}

- (id)initWithRegion:(CLRegion *)region location:(NSString *)location name:(NSString *)name friends:(NSMutableArray *)friends timestamp:(int)timestamp user:(Friend *)user;

+ (instancetype)fromSnapshot:(FDataSnapshot *)snapshot ofFriend:(Friend *)user;

@property (nonatomic, retain) CLRegion *region;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *friends;
@property (nonatomic, assign) int timestamp;
@property (nonatomic, retain) Friend *user;

@end
