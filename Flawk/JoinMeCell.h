//
//  JoinMeCell.h
//  Flawk
//
//  Created by Justin Brower on 4/7/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Friend.h"

@interface JoinMeCell : UITableViewCell {
    
    IBOutlet UILabel *friendName;
    IBOutlet
    Friend *this_friend;
    
    IBOutlet UIImageView *selectedButton;
    
}
+ (CGFloat)preferredHeightInView:(UIView *)parent;

- (void)applyFriend:(Friend *)f selected:(BOOL)selected;
- (void)setSelected:(BOOL)selected;

@end
