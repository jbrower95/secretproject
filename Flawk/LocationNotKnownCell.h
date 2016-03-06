//
//  LocationNotKnownCell.h
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friend.h"

@interface LocationNotKnownCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UIButton *whereAtButton;
@property (nonatomic, retain) IBOutlet UIButton *joinMeButton;

- (void)applyFriend:(Friend *)f;

+ (CGFloat)preferredHeightInView:(UIView *)parent;
@end
