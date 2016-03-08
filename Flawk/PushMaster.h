//
//  PushMaster.h
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Friend.h"
#import "API.h"

@interface PushMaster : NSObject

+ (void)sendLocationRequestPushToUser:(Friend *)f completion:(void (^)(BOOL sent, NSError *error))completion;
+ (void)sendMessageToUser:(Friend *)f message:(NSString *)message;

@end
