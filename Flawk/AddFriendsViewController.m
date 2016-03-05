//
//  AddFriendsViewController.m
//  Flawk
//
//  Created by Justin Brower on 3/4/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "AddFriendsViewController.h"
#import "Friend.h"
#import "API.h"

@implementation AddFriendsViewController
@synthesize friends;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"FriendCell"];
    }
    
    Friend *friend = [[API sharedAPI] friends][indexPath.row];
    [[cell textLabel] setText:[friend name]];
    
    
    NSString *reqId = [NSString stringWithFormat:@"%@%@",[[API sharedAPI] this_user].fbid , [friend fbid]];
    Firebase *requests = [[[API sharedAPI] firebase] childByAppendingPath:@"requests"];
    
    [requests observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([snapshot hasChild:reqId]) {
            FDataSnapshot *child = [snapshot childSnapshotForPath:reqId];
            BOOL accepted = [[[child childSnapshotForPath:@"accepted"] value] boolValue];
            if (accepted) {
                [[cell detailTextLabel] setText:@"Friend request accepted!"];
            } else {
                [[cell detailTextLabel] setText:@"Friend request pending."];
            }
        } else {
            [[cell detailTextLabel] setText:@""];
        }
    }];
    
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[API sharedAPI] friends].count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // Create a friend request in the database
    Friend *target = [[API sharedAPI] friends][indexPath.row];
    
    NSString *reqId = [NSString stringWithFormat:@"%@%@",[[API sharedAPI] this_user].fbid , [target fbid]];
    
    Firebase *requests = [[[API sharedAPI] firebase] childByAppendingPath:@"requests"];
    
    [requests observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([snapshot hasChild:reqId]) {
            NSLog(@"[API] Friend request already existed: %@", reqId);
        } else {
            NSLog(@"[API] Friend request being sent: %@", reqId);
            
            NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
            
            Firebase *request = [[[[API sharedAPI] firebase] childByAppendingPath:@"requests"] childByAppendingPath:reqId];
            [[request childByAppendingPath:@"from"] setValue:[[API sharedAPI] this_user].fbid];
            [[request childByAppendingPath:@"to"] setValue:[target fbid]];
            [[request childByAppendingPath:@"timestamp"] setValue:[NSNumber numberWithInt:timestamp]];
            [[request childByAppendingPath:@"accepted"] setValue:[NSNumber numberWithBool:NO]];
            [tableView reloadData];
        }
    }];
 
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self navigationController] navigationBar] setTintColor:[UIColor whiteColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    
    
    [super viewDidAppear:animated];
}


@end
