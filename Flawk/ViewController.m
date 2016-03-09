//
//  ViewController.m
//  Flawk
//
//  Created by Justin Brower on 12/2/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ViewController.h"
#import "API.h"
#import "Friend.h"
#import "LocationKnownCell.h"
#import "FriendLocationController.h"
#import "FeatureConfig.h"
#import "LocationNotKnownCell.h"
#import "MapCell.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize manager;
- (void)viewDidLoad {
    
    // Register for API notifications here.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFailed:) name:API_REFRESH_FAILED_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSuccess:) name:API_REFRESH_SUCCESS_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedFriendRequest:) name:API_RECEIVED_FRIEND_REQUEST_EVENT object:nil];
    offset = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationRequest:) name:@"LocationRequest" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAvailable:) name:@"LocationAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAvailable:) name:@"NewLocationAvailable" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:@"MessageReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:@"ReloadMainTable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:@"ReloadCheckins" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChosen:) name:@"LocationChosen" object:nil];
    
    self.navigationItem.title = @"Flawk";
    
    refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(reloadTable:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
    [tableView sendSubviewToBack:refreshControl];
    [tableView setDelegate:self];
    
    [self setCheckinDisabled];
    [[API sharedAPI] initLocations];
    
    friends = [[NSMutableArray alloc] init];
    
    /* Check if we're logged in */
    if (![[API sharedAPI] isLoggedIn]) {
        NSLog(@"Attempting to log in user...");
        [self login];
    } else {
        NSLog(@"User is logged in already!");
        [[API sharedAPI] loadExtendedUserInfoFromFacebook];
        [self loadAllFriends];
    }
    
    UIButton *plus = [[UIButton alloc] initWithFrame:CGRectMake(0,0,20,20)];
    [plus setImage:[UIImage imageNamed:@"plus"] forState:UIControlStateNormal];
    [plus addTarget:self action:@selector(addFriends:) forControlEvents:UIControlEventTouchUpInside];
    
    plusItem = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:plus];
    [plusItem setShouldHideBadgeAtZero:YES];
    [plusItem setTintColor:[UIColor whiteColor]];
    plusItem.badgeOriginX = 12;
    plusItem.badgeBGColor = [UIColor colorWithRed:0.091 green:0.714 blue:0.811 alpha:1.000];
    [self.navigationItem setRightBarButtonItem:plusItem];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 80)];
    [titleView setBackgroundColor:[UIColor clearColor]];
    
    locationView = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, 200, 20)];
    areaView = [[UILabel alloc] initWithFrame:CGRectMake(0, 40, 200, 20)];
    
    locationView.adjustsFontSizeToFitWidth = YES;
    areaView.adjustsFontSizeToFitWidth = YES;
    
    [locationView setTextAlignment:NSTextAlignmentCenter];
    [areaView setTextAlignment:NSTextAlignmentCenter];
    
    [locationView setFont:[UIFont systemFontOfSize:22]];
    [areaView setFont:[UIFont systemFontOfSize:14]];
    
    [locationView setTextColor:[UIColor whiteColor]];
    [areaView setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.7]];
    
    [titleView addSubview:locationView];
    [titleView addSubview:areaView];
    
    [locationView setText:@"Flawk"];
    [areaView setText:@"Locating..."];
    
    [titleView setUserInteractionEnabled:YES];
    UIButton *chooseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, titleView.frame.size.width, titleView.frame.size.height)];
    [chooseButton setBackgroundColor:[UIColor clearColor]];
    [chooseButton addTarget:self action:@selector(chooseLocation:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:chooseButton];
    
    self.navigationItem.titleView = titleView;
    
    [super viewDidLoad];
}

- (void)locationChosen:(NSNotification *)notification {
    
    NSDictionary *venue = [notification userInfo];
    
    NSDictionary *location_dict = venue[@"location"];
    
    [[[API sharedAPI] this_user] setLastKnownArea:[NSString stringWithFormat:@"%@, %@", [location_dict objectForKey:@"city"], [location_dict objectForKey:@"state"]]];
    [[[API sharedAPI] this_user] setLastKnownLocation:venue[@"name"]];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [locationView setText:venue[@"name"]];
        [areaView setText:[[API sharedAPI] this_user].lastKnownArea];
    });
}

- (void)chooseLocation:(id)sender {
    if ([[areaView text] isEqualToString:@"Locating..."]) {
        //bail
        return;
    } else {
        // choose location
        [self performSegueWithIdentifier:@"ChooseLocationSegue" sender:nil];
    }
    
}

- (void)receivedFriendRequest:(NSNotification *)notification {
    NSLog(@"Received friend request notification!");
    dispatch_async(dispatch_get_main_queue(), ^{
        int num_requests = 0;
        for (Request *r in [[API sharedAPI] outstandingFriendRequests]) {
            if (![r accepted]) {
                num_requests++;
            }
        }
        [plusItem setBadgeValue:[NSString stringWithFormat:@"%d", num_requests]];
    });
}


- (void)reload:(NSNotification *)not {
    dispatch_async(dispatch_get_main_queue(), ^{
        [tableView reloadData];
    });
}

- (void)setCheckinDisabled {
    [button setEnabled:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [refreshControl endRefreshing];
    [[API sharedAPI] getAllFriendsWithBlock:nil];
    
    if ([[[API sharedAPI] this_user] locationKnown]) {
        [self locationAvailable:nil];
    }
    
    [self receivedFriendRequest:nil];
}

- (void)reloadTable:(id)sender {
    [self loadAllFriends];
}

- (void)authorizeAgain {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Authorization Required" message:@"Please login with Facebook to use Flawk!" preferredStyle:UIAlertControllerStyleAlert];
    [controller addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:controller animated:YES completion:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(login) withObject:nil afterDelay:2.0];
        });
    }];
}

- (void)login {
    [[API sharedAPI] login];
}



- (void)locationRequest:(NSNotification *)pushNotification {
    NSLog(@"Got location request.");
    NSDictionary *userInfo = [pushNotification userInfo];
    
    if (userInfo != nil) {
        
        NSString *senderId = [userInfo objectForKey:@"from"];
        NSString *requestId = [userInfo objectForKey:@"id"];
        Friend *friend = [Friend friendWithFacebookId:senderId];
        
        if (friend == nil) {
            // Received request from unknown friend. Delete.
        }
        
        // Found friend. Show a prompt.
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ wants to know where you're at!", [friend nickname]] message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [controller addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // share location
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[API sharedAPI] getLocationAndAreaWithBlock:^{
                    [[API sharedAPI] shareLocationWithUser:friend completion:^(BOOL success, NSError *error) {
                        if (success) {
                            NSLog(@"Location shared!");
                        } else {
                            NSLog(@"Location failed to share: %@", error);
                        }
                    }];
                }];
            });
            
            
        }]];
        
        [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        
        [self presentViewController:controller animated:YES completion:^{
            // Delete the location request
            [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[[API sharedAPI] firebase].authData.uid] childByAppendingPath:@"location_requests"] childByAppendingPath:requestId] removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
                if (error == nil) {
                    NSLog(@"[API] Successfully dequeued friend request.");
                } else {
                    NSLog(@"[API] Couldn't dequeue location request.");
                }
            }];
        }];
    }
}

- (IBAction)addFriends:(id)sender {
    
    [self performSegueWithIdentifier:@"AddFriendsSegue" sender:self];
    
    
    /*
    // Example of a feature flag.
    [FeatureConfig featureEnabled:kFeatureAddFriends callback:^(BOOL enabled) {
        if (enabled) {
            [self performSegueWithIdentifier:@"AddFriendsSegue" sender:self];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Add friends not enabled!");
                UIAlertController *c = [UIAlertController alertControllerWithTitle:@"Error" message:@"Feature unavailable." preferredStyle:UIAlertControllerStyleAlert];
                [c addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }]];
                [self presentViewController:c animated:YES completion:nil];
            });
        }
    }];
     */
}

- (void)locationAvailable:(NSNotification *)notification {
    NSLog(@"Location available! Enabling checkin.");
    [button setEnabled:YES];
    [[API sharedAPI] getLocationAndAreaWithBlock:^{
        locationView.text = [[API sharedAPI] this_user].lastKnownLocation;
        areaView.text = [[API sharedAPI] this_user].lastKnownArea;
    }];
}

- (void)messageReceived:(NSNotification *)notification {
    NSLog(@"Received message!");
    
    NSDictionary *userInfo = [notification userInfo];
    
    NSString *from = [userInfo objectForKey:@"from"];
    NSString *name = @"Unknown";
    for (Friend *pal in [[API sharedAPI] friends]) {
        if ([[pal fbid] isEqualToString:from]) {
            name = [pal name];
            break;
        }
    }
    
    NSString *text = [userInfo objectForKey:@"text"];
    
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:name message:text preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil];
    [controller addAction:cancelAction];
    
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)refreshFailed:(id)sender {
    NSLog(@"Refresh failed: logging in again.");
    // Woah, couldn't login!
    [self login];
}

- (void)refreshSuccess:(NSNotification *)notification {
    [[API sharedAPI] initParse];
    [self loadAllFriends];
}

- (void)loadAllFriends {
    [[API sharedAPI] getAllFriendsWithBlock:^(NSArray *receivedFriends, NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
        
        NSLog(@"Got %lu friends.", (unsigned long)[receivedFriends count]);
        [refreshControl endRefreshing];
    }];
}

- (IBAction)checkin:(id)sender {
    [self performSegueWithIdentifier:@"ShareLocationSegue" sender:nil];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return [MapCell preferredHeightInView:tableView];
    } else {
        Friend *f = [[API sharedAPI] confirmedFriends][indexPath.row-1];
        if ([f locationKnown]) {
            return [LocationKnownCell preferredHeightInView:tableView];
        } else {
            return [LocationNotKnownCell preferredHeightInView:tableView];
        }
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        // The map cell
        MapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MapCell"];
        if (cell == nil) {
            cell = [[MapCell alloc] init];
        }
        [cell setup];
        return cell;
    }
    
    BOOL patterned = !(BOOL)(indexPath.row % 2);
    
    /* Apply friend to cell */
    Friend *friend = [[[API sharedAPI] confirmedFriends] objectAtIndex:indexPath.row - 1];
    
    if ([friend locationKnown]) {
        LocationKnownCell *cell = (LocationKnownCell *)[_tableView dequeueReusableCellWithIdentifier:@"LocationKnownCell"];

        if (cell == nil) {
            cell = [[LocationKnownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationKnownCell"];
        }

        if (friend != nil) {
            // apply them
            [cell applyFriend:friend];
        }
        
        if (patterned) {
            [cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Mask"]]];
        } else {
            [cell setBackgroundColor:[UIColor whiteColor]];
        }
        
        return cell;
    } else {
        LocationNotKnownCell *cell = (LocationNotKnownCell *)[_tableView dequeueReusableCellWithIdentifier:@"LocationNotKnownCell"];
        
        if (cell == nil) {
            cell = [[LocationNotKnownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LocationNotKnownCell"];
        }
        
        if (friend != nil) {
            // apply them
            [cell applyFriend:friend];
        }
        
        if (patterned) {
            [cell setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"Mask"]]];
        } else {
            [cell setBackgroundColor:[UIColor whiteColor]];
        }
        
        return cell;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[API sharedAPI] confirmedFriends] count] + 1;
}


- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return;
    }
    
    NSString *segue = @"FriendLocationSegue";
    
    Friend *f = [[[API sharedAPI] confirmedFriends] objectAtIndex:indexPath.row-1];
    
    if ([f locationKnown]) {
        // zoom over this person
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ZoomFriend" object:nil userInfo:@{@"id" : f.fbid}];
    }
    
    [table deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FriendLocationSegue"]) {
             NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
             FriendLocationController *destViewController = segue.destinationViewController;
             destViewController.person = [[[API sharedAPI] confirmedFriends] objectAtIndex:indexPath.row-1];
            destViewController.navigationItem.title = [destViewController.person name];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
