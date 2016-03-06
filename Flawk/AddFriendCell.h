//
//  AddFriendCell.h
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friend.h"

@interface AddFriendCell : UITableViewCell

- (id)initWithFriend:(Friend *)f;
- (void)applyFriend:(Friend *)f;
- (void)setStatus:(NSString *)status;
- (IBAction)addFriend:(id)sender;

@property (nonatomic, retain) IBOutlet UIImageView *image;
@property (nonatomic, retain) IBOutlet UILabel *nameField;
@property (nonatomic, retain) IBOutlet UILabel *timestampField;
@property (nonatomic, retain) IBOutlet UIButton *addButton;
@property (nonatomic, retain) Friend *fr;
@end
