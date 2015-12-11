//
//  Checkin.h
//  Flawk
//
//  Created by Justin Brower on 12/7/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
@interface Checkin : NSObject <NSCoding> {
    CLRegion *region;
    NSString *location;
    NSString *name;
    NSSet *friends;
}

- (id)initWithRegion:(CLRegion *)region location:(NSString *)location name:(NSString *)name friends:(NSSet *)friends;

@property (nonatomic, retain) CLRegion *region;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *friends;

@end
