//
//  JoinMeCell.m
//  Flawk
//
//  Created by Justin Brower on 4/7/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "JoinMeCell.h"

@implementation JoinMeCell

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    // Maintain a certain aspect ratio
    float ratio = 60.0f / 320.0f;
    return ratio * [parent frame].size.height;
}

- (void)applyFriend:(Friend *)f selected:(BOOL)selected {
    this_friend = f;
    [friendName setText:[f name]];
    [self setSelected:selected];
}

- (void)setSelected:(BOOL)selected {
    [selectedButton setImage:selected ? [UIImage imageNamed:@"checkbox-checked"] : [UIImage imageNamed:@"checkbox"]];
}

- (void)awakeFromNib {
    //Changes done directly here, we have an object
    [super awakeFromNib];
    [selectedButton setUserInteractionEnabled:NO];
}


@end
