//
//  Request.h
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Firebase/Firebase.h>

/* A friend request */
@interface Request : NSObject
@property (nonatomic, retain) NSString *to;
@property (nonatomic, retain) NSString *from;
@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL accepted;
- (void)accept:(void (^)(BOOL success, NSError *error))completion;
- (id)initWithTo:(NSString *)toFbId from:(NSString *)fromFbId timestamp:(NSTimeInterval)timestamp accepted:(BOOL)accepted;
- (id)initWithSnapshot:(FDataSnapshot *)snapshot;
- (BOOL)isEqual:(id)object;
@end
