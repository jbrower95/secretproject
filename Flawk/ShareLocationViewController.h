//
//  ShareLocationViewController.h
//  Flawk
//
//  Created by Justin Brower on 12/5/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShareLocationViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    NSMutableSet<NSString *> *selections;
    IBOutlet UITableView *tableView;
}

@property IBOutlet UITableView *tableView;
@end
