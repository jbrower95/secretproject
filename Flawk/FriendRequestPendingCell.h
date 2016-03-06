//
//  FriendRequestPendingCell.h
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Request.h"
#import "Friend.h"

@interface FriendRequestPendingCell : UITableViewCell
- (void)setFriendRequest:(Request *)r from:(Friend *)name;
- (id)initWithFriendRequest:(Request *)request from:(Friend *)name;

- (IBAction)acceptRequest:(id)sender;
- (IBAction)ignoreRequest:(id)sender;

@property (nonatomic, retain) IBOutlet UILabel *nameField;
@property (nonatomic, retain) IBOutlet UILabel *timestampField;
@property (nonatomic, retain) IBOutlet UIImageView *image;

@property (nonatomic, retain) IBOutlet UIButton *addButton;
@property (nonatomic, retain) IBOutlet UIButton *ignoreButton;


@property (nonatomic, retain) Request *request;
@end
