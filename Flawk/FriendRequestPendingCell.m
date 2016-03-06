//
//  FriendRequestPendingCell.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "FriendRequestPendingCell.h"
#import "NSDate+Prettify.h"
#import "UIImageView+Web.h"
#import "Friend.h"
#import "API.h"

@implementation FriendRequestPendingCell

@synthesize  request, nameField, timestampField, image;
- (id)initWithFriendRequest:(Request *)r from:(Friend *)from {
    if (self = [super init]) {
        self.request = r;
        [self.nameField setText:from.name];
        [self.timestampField setText:[[NSDate date] prettifiedStringFromReferenceDate:[NSDate dateWithTimeIntervalSince1970:r.timestamp]]];
    }
    return self;
}

- (IBAction)acceptRequest:(id)sender {
    [self.request accept:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"[Request] Successfully accepted!");
            [self.timestampField setText:@"accepted request"];
            [self.ignoreButton setHidden:YES];
            [self.addButton setHidden:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadTable" object:nil];
        } else {
            NSLog(@"[Request] Failed");
        }
    }];
}
- (IBAction)ignoreRequest:(id)sender {
    NSString *rid = [NSString stringWithFormat:@"%@%@", self.request.from, self.request.to];
    [[[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:rid] removeValue];
}


- (void)setFriendRequest:(Request *)r from:(Friend *)from {
    self.request = r;
    [self.nameField setText:from.name];
    
    NSString *time = [[NSDate date] prettifiedStringFromReferenceDate:[NSDate dateWithTimeIntervalSince1970:self.request.timestamp]];
    
    [self.ignoreButton setHidden:r.accepted];
    [self.addButton setHidden:r.accepted];
    
    [self.timestampField setText:[NSString stringWithFormat:@"requested you %@", time]];
    [from loadFacebookProfilePictureUrlWithBlock:^(NSString *url) {
        [self.image loadRemoteUrl:url];
    }];
}

@end
