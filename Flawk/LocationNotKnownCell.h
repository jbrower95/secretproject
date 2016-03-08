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
@property (nonatomic, retain) Friend *fr;
- (void)applyFriend:(Friend *)f;
- (IBAction)whereAtPressed:(id)sender;
+ (CGFloat)preferredHeightInView:(UIView *)parent;
@end
