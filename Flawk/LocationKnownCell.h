//
//  FriendCellTableViewCell.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friend.h"
@interface LocationKnownCell : UITableViewCell {
    
    IBOutlet UILabel *name;
    IBOutlet UILabel *location;
    IBOutlet UILabel *area;
    
    IBOutlet UIButton *whereAtButton;
    
    Friend *model;
}

@property (nonatomic, retain) IBOutlet UILabel *name;
@property (nonatomic, retain) IBOutlet UILabel *location;
@property (nonatomic, retain) IBOutlet UILabel *area;
@property (nonatomic, retain) IBOutlet UIButton *whereAtButton;

@property (nonatomic, retain) Friend *model;

+ (CGFloat)preferredHeightInView:(UIView *)parent;

- (void)applyFriend:(Friend *)f;

@end
