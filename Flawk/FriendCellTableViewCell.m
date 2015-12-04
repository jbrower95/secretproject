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
    
    [whereAtButton setTitle:@"Pinged!" forState:UIControlStateNormal];
    
    [self performSelector:@selector(resetButton:) withObject:nil afterDelay:8];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"WhereAtRequest" object:nil userInfo:@{@"username" : [self.model name], @"facebookId" : [self.model fbid]}];
}


- (void)resetButton:(id)sender {
    [whereAtButton setTitle:@"Where at?" forState:UIControlStateNormal];
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
