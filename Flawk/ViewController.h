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
    
    IBOutlet UITableView *tableView;
    
    IBOutlet UIButton *button;
    
    CLLocationManager *manager;
    
    UIRefreshControl *refreshControl;
    
    NSMutableArray *friends;
}
@property (nonatomic, strong) CLLocationManager *manager;

- (IBAction)addFriends:(id)sender;

@end

