//
//  ViewController.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Friend.h"

@interface ViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, NSURLSessionDataDelegate, CLLocationManagerDelegate> {
    
    NSArray *friends;
    
    IBOutlet UITableView *tableView;
    
    UIButton *button;
    
    CLLocationManager *manager;
    
    Friend *selectedFriend;
}
@property (nonatomic, retain) NSArray *friends;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, retain) Friend *selectedFriend;

@end

