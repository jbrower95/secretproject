//
//  AddFriendsViewController.h
//  Flawk
//
//  Created by Justin Brower on 3/4/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSDate+Prettify.h"
#import <Firebase/Firebase.h>
@interface AddFriendsViewController : UITableViewController

@property (nonatomic, retain) NSMutableArray *friends;
@property (nonatomic, assign) FirebaseHandle handle;
@end
