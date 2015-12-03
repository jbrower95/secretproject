//
//  ViewController.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ViewController.h"
#import "Api.h"
#import "Friend.h"
#import "FriendCellTableViewCell.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <FBSDKCoreKit/FBSDKConstants.h>

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    
    // Register for API notifications here.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFailed:) name:API_REFRESH_FAILED_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSuccess:) name:API_REFRESH_SUCCESS_EVENT object:nil];
    
    self.navigationItem.title = @"Where are ü now";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Friends" style:UIBarButtonItemStylePlain target:self action:@selector(addFriends:)];
    
    /* Check if we're logged in */
    [API getAllFriendsWithBlock:^(NSArray *receivedFriends, NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
        
        NSLog(@"Got %lu friends.", (unsigned long)[receivedFriends count]);
        
        self.friends = receivedFriends;
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [self.tableView reloadData];
        });
        
    }];
    
    if (![API isLoggedIn]) {
        NSLog(@"Attempting to log in user...");
        [self login];
    } else {
        NSLog(@"User is logged in!");
        [API refreshFacebookLogin];
    }
    
    [super viewDidLoad];
}

- (void)login {
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile", @"email", @"user_friends"]
     fromViewController:self
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error) {
             NSLog(@"Process error");
             NSLog(@"%@", [error localizedDescription]);
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
         } else {
             NSLog(@"Logged in");
         }
     }];
}

- (void)refreshFailed:(id)sender {
    NSLog(@"Refresh failed: logging in again.");
    // Woah, couldn't login!
    [self login];
}

- (void)refreshSuccess:(id)sender {
    NSLog(@"Login is officially good.");
    NSLog(@"Verifying Facebook permissions...");
    
    NSSet *declinedPermissions = [[FBSDKAccessToken currentAccessToken] declinedPermissions];
    
    if ([declinedPermissions count] > 0) {
        NSLog(@"Error -- User declined permissions. App won't work properly. ");
        // TODO: Show some UI for this.
    }
    
    NSSet *permissions = [[FBSDKAccessToken currentAccessToken] permissions];
    
    NSLog(@"%d permissions granted", [permissions count]);
    
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me/friends" parameters:@{@"fields" : @"id, name, email"}];
    
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
        if (error == nil) {
            // No problemo.
            NSLog(@"%@", result);
            
            NSDictionary *parsedResult = (NSDictionary *)result;
            
            NSArray *friends = [parsedResult objectForKey:@"data"];
            
            if (friends != nil) {
                NSLog(@"Downloaded friends from facebook: %d.", [friends count]);
            } else {
                NSLog(@"No friends from Facebook.");
            }
            
        } else {
            // Error
            if ([error code] == FBSDKGraphRequestGraphAPIErrorCode) {
                NSLog(@"Experienced an error with the graph api.");
                NSLog(@"%@", [[error userInfo] objectForKey:FBSDKGraphRequestErrorParsedJSONResponseKey]);
            }
            
            NSLog(@"%@", [error localizedDescription]);
        }
    }];
    
    
    
}

- (void)viewWillLayoutSubviews {
    
    // Arrange our views here.
    
    
}
     
- (IBAction)addFriends:(id)sender {
         
    NSLog(@"Ayy");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FriendCellTableViewCell *cell = (FriendCellTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"FriendCell"];
    
    if (cell == nil) {
        cell = [[FriendCellTableViewCell alloc] init];
    }
    
    /* Apply friend to cell */
    Friend *friend = [self.friends objectAtIndex:indexPath.row];
    if (friend != nil) {
        // apply them
        [cell applyFriend:friend];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.friends count];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
