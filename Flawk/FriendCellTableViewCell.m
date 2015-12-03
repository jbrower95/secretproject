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
        }
    }
}

- (void)layoutSubviews {
    CGFloat middle = self.frame.size.height / 2;
    
    const CGFloat location_padding = 3;
    
    CGRect labelRect = [[name text]
                        boundingRectWithSize:CGSizeMake(200, 0)
                        options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:@{
                                     NSFontAttributeName : [UIFont systemFontOfSize:17]
                                     }
                        context:nil];
    
    // Vertically center the name with 16px padding on the left.
    [name setFrame:CGRectMake(16, middle - name.frame.size.height / 2, labelRect.size.width, labelRect.size.height)];
    
    int location_width = location.frame.size.width;
    
    int total_height = location.frame.size.height + area.frame.size.height + location_padding;
    
    [location setFrame:CGRectMake(self.frame.size.width * .7, middle - total_height / 2, location_width, location.frame.size.height)];
    
    [area setFrame:CGRectMake(location.frame.origin.x, location.frame.origin.y + location.frame.size.height + location_padding, location.frame.size.width, location.frame.size.height)];
    
    [whereAtButton setFrame:CGRectMake(location.frame.origin.x, middle - whereAtButton.frame.size.height / 2, whereAtButton.frame.size.width, whereAtButton.frame.size.height)];
}

@end
