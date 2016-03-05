//
//  Checkin.h
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface PersistentCheckin : NSObject <NSCoding> {
    CLRegion *region;
    NSString *location;
    NSString *name;
    NSMutableArray *friends;
}

- (id)initWithRegion:(CLRegion *)region location:(NSString *)location name:(NSString *)name friends:(NSMutableArray *)friends;

/* Creates a checkin object on the server, marks all other checkins as non current and makes this one current. */
- (void)markActive;

@property (nonatomic, retain) CLRegion *region;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableArray *friends;

@end
