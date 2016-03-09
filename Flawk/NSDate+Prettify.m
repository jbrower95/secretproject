//
//  NSDate+Prettify.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "NSDate+Prettify.h"

@implementation NSDate (Prettified)

- (NSString *)prettifiedStringFromReferenceDate:(NSDate *)past {
    
    NSTimeInterval interval = [self timeIntervalSinceReferenceDate] - [past timeIntervalSinceReferenceDate];
    // Number of seconds.
    
    if (interval <= 60) {
        return [NSString stringWithFormat:@"%d second%@ ago", (int)interval, (int)interval != 1 ? @"s" : @""];
    }
    
    NSTimeInterval minutes = (int)(interval / 60);
    if (minutes <= 60) {
        return [NSString stringWithFormat:@"%d minute%@ ago", (int)minutes, (int)minutes != 1 ? @"s" : @""];
    }
    
    NSTimeInterval hours = (int)(minutes / 60);
    if (hours <= 24) {
        return [NSString stringWithFormat:@"%d hour%@ ago", (int)hours, (int)hours != 1 ? @"s" : @""];
    }
    
    NSTimeInterval days = (int)(hours / 24);
    if (days < 30) {
        return [NSString stringWithFormat:@"%d day%@ ago", (int)days, (int)days != 1 ? @"s" : @""];
    }
    
    return @"Forever ago";
}

- (NSString *)prettifiedStringAbbreviationFromReferenceDate:(NSDate *)past {
    
    NSTimeInterval interval = [self timeIntervalSinceReferenceDate] - [past timeIntervalSinceReferenceDate];
    // Number of seconds.
    
    if (interval <= 60) {
        return [NSString stringWithFormat:@"%ds", (int)interval];
    }
    
    NSTimeInterval minutes = (int)(interval / 60);
    if (minutes <= 60) {
        return [NSString stringWithFormat:@"%dm", (int)minutes];
    }
    
    NSTimeInterval hours = (int)(minutes / 60);
    if (hours <= 24) {
        return [NSString stringWithFormat:@"%dh", (int)hours];
    }
    
    NSTimeInterval days = (int)(hours / 24);
    if (days < 30) {
        return [NSString stringWithFormat:@"%dd", (int)days];
    }
    
    return @"∞";
}

@end
