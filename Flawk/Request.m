//
//  Request.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "Request.h"
#import "API.h"

@implementation Request

@synthesize to, from, timestamp, accepted;

- (void)accept:(void (^)(BOOL success, NSError *error))completion {
    NSString *totalId = [NSString stringWithFormat:@"%@%@", self.to, self.from];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:totalId] childByAppendingPath:@"accepted"] setValue:[NSNumber numberWithBool:true] withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error != nil) {
            completion(false, error);
            return;
        }
        
        /* Add the friend to your list */
        [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[API sharedAPI].firebase.authData.uid] childByAppendingPath:@"friends"] childByAutoId] setValue:self.from];
        
        /* Add the friend to your OTHER friend's friends list. */
        FQuery *query = [[[[API sharedAPI] firebase] childByAppendingPath:@"fbids"] queryOrderedByKey];
        query = [query queryEqualToValue:self.from];
        [query observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            
            if (snapshot.childrenCount == 0) {
                completion(false, [NSError errorWithDomain:@"com.jbrower.Flawk" code:245 userInfo:@{@"error" : @"User does not exist."}]);
                return;
            }
            
            FDataSnapshot *child = [snapshot.children nextObject];
            NSString *uid = [child value];
            
            // Add ourselves
            NSLog(@"[Friend Request] Adding ourselves to the other persons friendlist.");
            [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"friends"] childByAutoId] setValue:[API sharedAPI].this_user.fbid withCompletionBlock:^(NSError *error, Firebase *ref) {
                NSLog(@"[Friend Request] All done (%@, %@)",uid, error);
                [self setAccepted:true];
                completion(error == nil, error);
                return;
            }];
        } withCancelBlock:^(NSError *error) {
            NSLog(@"Error: Couldn't accept friend request - %@", [error localizedDescription]);
            completion(false, error);
            return;
        }];
    }];
    
   }
- (id)initWithTo:(NSString *)toFbId from:(NSString *)fromFbId timestamp:(NSTimeInterval)_timestamp accepted:(BOOL)_accepted {
    if (self = [super init]) {
        self.to = toFbId;
        self.from = fromFbId;
        self.timestamp = _timestamp;
        self.accepted = _accepted;
    }
    
    return self;
}

- (id)initWithSnapshot:(FDataSnapshot *)snapshot {
    NSString *_from = [[snapshot childSnapshotForPath:@"from"] value];
    NSString *_to = [[snapshot childSnapshotForPath:@"to"] value];
    NSTimeInterval _t = [[[snapshot childSnapshotForPath:@"timestamp"] value] intValue];
    BOOL _accepted = [[[snapshot childSnapshotForPath:@"accepted"] value] boolValue];
    return [self initWithTo:_to from:_from timestamp:_t accepted:_accepted];
}

- (BOOL)isEqual:(id)object {
    
    if (![object isKindOfClass:[Request class]]){
        return NO;
    }
    
    Request *request = (Request *)object;
    return [[request to] isEqualToString:self.to] && [[request from] isEqualToString:self.from];
}


@end
