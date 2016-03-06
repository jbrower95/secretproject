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
#import "FriendRequestPendingCell.h"
#import "AddFriendCell.h"
#import "Request.h"

@implementation AddFriendsViewController
@synthesize friends, handle;

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell;
    
    if ([[API sharedAPI] outstandingFriendRequests].count > 0) {
        // Friend requests exist!
        
        switch (indexPath.section) {
            case 0: {
                // Outstanding friend requests
                Request *r = [[API sharedAPI] outstandingFriendRequests][indexPath.row];
                cell = [tableView dequeueReusableCellWithIdentifier:@"FriendRequestPendingCell"];
                Friend *fromFriend = nil;
                for (Friend *friend in [[API sharedAPI] friends]) {
                    if ([[friend fbid] isEqualToString:[r from]]) {
                        fromFriend = friend;
                        break;
                    }
                }
                
                if (cell == nil) {
                    cell = [[FriendRequestPendingCell alloc] initWithFriendRequest:r from:fromFriend];
                }
                
                [(FriendRequestPendingCell *)cell setFriendRequest:r from:fromFriend];
                
                return cell;
            }
            case 1: {
                // Random people to add
                Friend *friend = [[API sharedAPI] friends][indexPath.row];
                cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell"];
                
                if (cell == nil) {
                    cell = [[AddFriendCell alloc] initWithFriend:friend];
                }
                [(AddFriendCell *)cell applyFriend:friend];
                [(AddFriendCell *)cell setStatus:@""];
                
                for (Request *request in [[API sharedAPI] sentFriendRequests]) {
                    if ([[request to] isEqualToString:[friend fbid]]) {
                        if ([request accepted]) {
                            [(AddFriendCell *)cell setStatus:@"request accepted!"];
                        } else {
                            [(AddFriendCell *)cell setStatus:@"request sent"];
                        }
                        break;
                    }
                }
                
                return cell;
            }
                
        }
        
    } else {
        // Random people to add
        Friend *friend = [[API sharedAPI] friends][indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCell"];
        
        if (cell == nil) {
            cell = [[AddFriendCell alloc] initWithFriend:friend];
        }
        [(AddFriendCell *)cell applyFriend:friend];
        [(AddFriendCell *)cell setStatus:@""];
        
        for (Request *request in [[API sharedAPI] sentFriendRequests]) {
            if ([[request to] isEqualToString:[friend fbid]]) {
                if ([request accepted]) {
                    [(AddFriendCell *)cell setStatus:@"request accepted!"];
                } else {
                    [(AddFriendCell *)cell setStatus:@"request sent"];
                }
                break;
            }
        }
        return cell;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    int num_requests = (int) [[API sharedAPI] outstandingFriendRequests].count;
    
    if (num_requests > 0) {
        switch (section) {
            case 0:
                // active friend requests
                return num_requests;
            case 1:
                // explore friends
                return [[API sharedAPI] friends].count;
        }
    } else {
        return [[[API sharedAPI] friends] count];
    }
    
    return [[API sharedAPI] friends].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([[API sharedAPI] outstandingFriendRequests].count > 0) {
        // Friend requests exist!
        return 2;
    } else {
        // Simply explore
        return 1;
    }
}

- (void)reload:(NSNotification *)notif {
    
    NSMutableArray *outstandingRequests = [NSMutableArray array];
    for (Request *request in [[API sharedAPI] outstandingFriendRequests]) {
        if ([request accepted] && [[NSDate date] timeIntervalSince1970] - [request timestamp] > 30) {
            
        } else {
            [outstandingRequests addObject:request];
        }
    }
    
    [[API sharedAPI] setOutstandingFriendRequests:outstandingRequests];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    // Create a friend request in the database
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[[self navigationController] navigationBar] setTintColor:[UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:API_RECEIVED_FRIEND_REQUEST_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:@"ReloadTable" object:nil];
    
    Firebase *requests = [[[API sharedAPI] firebase] childByAppendingPath:@"requests"];
    FQuery *query = [requests queryOrderedByChild:@"from"];
    query = [query queryEqualToValue:[API sharedAPI].this_user.fbid];
    handle = [query observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        
        if (!snapshot.exists) {
            return;
        }
        FDataSnapshot *child;
        
        for (child in [snapshot children]) {
            NSString *requestid = child.key;
            Request *r = [[Request alloc] initWithSnapshot:child];
            if ([[[API sharedAPI] sentFriendRequests] containsObject:r]) {
                [[[API sharedAPI] sentFriendRequests] removeObject:r];
            }
            
            [[[API sharedAPI] sentFriendRequests] addObject:r];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}

- (void)dealloc {
    Firebase *requests = [[[API sharedAPI] firebase] childByAppendingPath:@"requests"];
    [requests removeAuthEventObserverWithHandle:handle];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


@end
