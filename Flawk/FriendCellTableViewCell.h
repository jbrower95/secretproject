//
//  FriendCellTableViewCell.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friend.h"
@interface FriendCellTableViewCell : UITableViewCell {
    
    IBOutlet UILabel *name;
    IBOutlet UILabel *location;
    IBOutlet UILabel *area;
    
    IBOutlet UIButton *whereAtButton;
    
}


- (void)applyFriend:(Friend *)f;

@end
