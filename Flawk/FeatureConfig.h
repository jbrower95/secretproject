//
//  FeatureConfig.h
//  Flawk
//
//  Created by Justin Brower on 3/4/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _kFeature {
    kFeatureAddFriends
} Feature;

@interface FeatureConfig : NSObject
+ (void)featureEnabled:(Feature)feature callback:(void (^)(BOOL enabled))callback;
@end
