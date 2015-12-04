//
//  FriendCellTableViewCell.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "FriendCellTableViewCell.h"

@implementation FriendCellTableViewCell

- (void)awakeFromNib {
    whereAtButton.layer.cornerRadius = 4;
    [name sizeToFit];
    
    self.accessoryType = UITableViewCellAccessoryNone;
}

- (IBAction)buttonPressed:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WhereAtRequest" object:nil userInfo:@{@"username" : [self.model name], @"facebookId" : [self.model fbid]}];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    
    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)applyFriend:(Friend *)f {
    self.model = f;
    if (f != nil) {
        [name setText:[f name]];
        
        BOOL locationKnown = [f locationKnown];
        
        [location setHidden:!locationKnown];
        [area setHidden:!locationKnown];
        [whereAtButton setHidden:locationKnown];
        
        if (locationKnown) {
            [location setText:[f lastKnownLocation]];
            [area setText:[f lastKnownArea]];
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.selectionStyle = UITableViewCellSelectionStyleDefault;
        } else {
            self.accessoryType = UITableViewCellAccessoryNone;
            self.selectionStyle = UITableViewCellSelectionStyleNone;
        }
    }
}

@end
