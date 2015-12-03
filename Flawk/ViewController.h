//
//  ViewController.h
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UITableViewController {
    NSArray *friends;
    
    UITableView *tableView;
}
@property (nonatomic, retain) NSArray *friends;

@end

