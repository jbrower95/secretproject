//
//  Request.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "Request.h"
#import "API.h"
#import "PushMaster.h"

@implementation Request

@synthesize to, from, timestamp, accepted;

- (void)accept:(void (^)(BOOL success, NSError *error))completion {
    NSString *totalId = [NSString stringWithFormat:@"%@%@", self.from, self.to];
    [[[[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:totalId] childByAppendingPath:@"accepted"] setValue:[NSNumber numberWithBool:true] withCompletionBlock:^(NSError *error, Firebase *ref) {
        
        if (error != nil) {
            completion(false, error);
            return;
        }
        
        NSString *fromid = self.from;
        Friend *fromFriend = [Friend friendWithFacebookId:[fromid substringFromIndex:[@"facebook:" length]]];
        
        NSDictionary *v = @{@"since" : [NSNumber numberWithInt:[[NSDate date] timeIntervalSince1970]]};
        
        /* Add the friend to your list */
        [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[API sharedAPI].firebase.authData.uid] childByAppendingPath:@"friends"] childByAppendingPath:fromid] updateChildValues:v withCompletionBlock:nil];
        
        /* Add the friend to your OTHER friend's friends list. */
        FQuery *query = [[[[API sharedAPI] firebase] childByAppendingPath:@"fbids"] queryOrderedByKey];
        query = [query queryEqualToValue:self.from];
        
        NSString *uid = self.from;
        
        // Add ourselves to the other person's list
        NSLog(@"[Friend Request] Adding ourselves to the other persons friendlist.");
        [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:uid] childByAppendingPath:@"friends"] childByAppendingPath:[API sharedAPI].firebase.authData.uid] updateChildValues:v withCompletionBlock:^(NSError *error, Firebase *ref) {
            
            if (error == nil) {
                [PushMaster sendAcceptedFriendRequestPushToUser:fromFriend completion:^(BOOL sent, NSError *error) {
                    if (sent || (error == nil)) {
                        NSLog(@"Push sent!");
                    } else {
                        NSLog(@"Push failed: %@", error);
                    }
                }];
                [self setAccepted:true];
            } else {
                NSLog(@"Error: Couldn't accept friend request (%@)", error);
            }
            
            NSLog(@"[Friend Request] All done (%@, %@)",uid, error);
            completion(error == nil, error);
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
