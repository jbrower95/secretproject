//
//  LocationNotKnownCell.m
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "LocationNotKnownCell.h"
#import "API.h"
#import <Firebase/Firebase.h>

@implementation LocationNotKnownCell

@synthesize nameLabel, whereAtButton, joinMeButton, fr;

- (void)applyFriend:(Friend *)f {
    self.nameLabel.text = [f name];
    self.fr = f;
}

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    float ratio = 60.0 / 320.0f;
    return ratio * parent.frame.size.width;
}

- (IBAction)whereAtPressed:(id)sender {
    [[API sharedAPI] requestWhereAt:self.fr completion:^{
        [self.whereAtButton setTitle:@"PINGED" forState:UIControlStateNormal];
        [self.whereAtButton setEnabled:NO];
    }];
}


@end

