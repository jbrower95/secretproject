//
//  AddFriendCell.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "AddFriendCell.h"
#import "NSDate+Prettify.h"
#import "UIImageView+Web.h"
#import "API.h"
#import "PushMaster.h"

@implementation AddFriendCell

@synthesize fr, nameField, timestampField, addButton;

- (id)initWithFriend:(Friend *)f {
    
    if (self = [super init]) {
        self.fr = f;
    }
    
    [self applyFriend:fr];
    
    return self;
}

- (IBAction)addFriend:(id)sender {
    
    Friend *target = fr;
    
    NSString *targetId = [NSString stringWithFormat:@"facebook:%@", [target fbid]];
    NSString *fromId = [NSString stringWithFormat:@"facebook:%@", [[API sharedAPI] this_user].fbid];
    
    NSString *reqId = [NSString stringWithFormat:@"%@%@",fromId,targetId];
    
    int timestamp = [[NSDate date] timeIntervalSince1970];
    
    Firebase *request = [[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:reqId];
    
    NSDictionary *values = @{
                             @"from" : fromId,
                             @"to" : targetId,
                             @"timestamp" : [NSNumber numberWithInt:timestamp],
                             @"accepted" : [NSNumber numberWithBool:NO]
                             };
    
    [request updateChildValues:values withCompletionBlock:^(NSError *error, Firebase *ref) {
      
        if (error == nil) {
            // Send the push
            [PushMaster sendFriendRequestPushToUser:fr completion:^(BOOL sent, NSError *error) {
                if (sent || (error == nil)) {
                    NSLog(@"Push sent!");
                } else {
                    NSLog(@"Push failed: %@", error);
                }
            }];
        }
        
    }];
    [self.timestampField setText:@"Friend request sent!"];
    [self.addButton setHidden:YES];
}


- (void)setStatus:(NSString *)status {
    [self.timestampField setText:status];
}

- (void)applyFriend:(Friend *)friend {
    self.fr = friend;
    self.nameField.text = [friend name];
    self.timestampField.text = @"";
    self.image.layer.masksToBounds = YES;
    [self.image.layer setCornerRadius:4];
    [friend loadFacebookProfilePictureUrlWithBlock:^(NSString *url) {
        if (url != nil) {
            [self.image loadRemoteUrl:url];
        }
    }];
}


@end
