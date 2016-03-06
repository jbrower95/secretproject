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
    
    NSString *reqId = [NSString stringWithFormat:@"%@%@",[[API sharedAPI] this_user].fbid , [target fbid]];
    
    int timestamp = [[NSDate date] timeIntervalSince1970];
    
    Firebase *request = [[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:reqId];
    
    NSDictionary *values = @{
                             @"from" : [[API sharedAPI] this_user].fbid,
                             @"to" : [target fbid],
                             @"timestamp" : [NSNumber numberWithInt:timestamp],
                             @"accepted" : [NSNumber numberWithBool:NO]
                             };
    
    [request updateChildValues:values withCompletionBlock:nil];
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
