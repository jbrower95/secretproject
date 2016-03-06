//
//  LocationNotKnownCell.m
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "LocationNotKnownCell.h"

@implementation LocationNotKnownCell

@synthesize nameLabel, whereAtButton, joinMeButton;

- (void)applyFriend:(Friend *)f {
    self.nameLabel.text = [f name];
}

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    float ratio = 60.0 / 320.0f;
    return ratio * parent.frame.size.width;
}
@end
