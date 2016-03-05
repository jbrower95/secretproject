//
//  FeatureConfig.m
//  Flawk
//
//  Created by Justin Brower on 3/4/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "FeatureConfig.h"
#import "Firebase.h"
#import "API.h"

@implementation FeatureConfig


+ (void)featureEnabled:(Feature)feature callback:(void (^)(BOOL enabled))callback {
    
    NSString *featureCode = [self featureCodes][feature];
    
    Firebase *firebase = [[[API sharedAPI] firebase] childByAppendingPath:@"features"];
    [firebase observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([snapshot exists]) {
            if ([snapshot hasChild:featureCode]){
                // This feature exists
                
                FDataSnapshot *child = [snapshot childSnapshotForPath:featureCode];
                callback([[child value] boolValue]);
            } else {
                // Feature doesn't exist
                callback(false);
            }
        } else {
            // Can't even find set of features.
            callback(false);
        }
    }];
}

+ (NSArray *)featureCodes
{
    static NSArray *featureCodes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        featureCodes = @[@"friend_request"];
    });
    return featureCodes;
}


@end
