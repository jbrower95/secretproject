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
#import "JoinMeCell.h"
#import "AudioHelper.h"

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showCheckin:) name:@"ShowCheckin" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:@"MessageReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:@"ReloadMainTable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload:) name:@"ReloadCheckins" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationChosen:) name:@"LocationChosen" object:nil];
    
    self.navigationItem.title = @"Flawk";
    locationAvailable = NO;
    refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(reloadTable:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
    [tableView sendSubviewToBack:refreshControl];
    [tableView setDelegate:self];
    
    [self setCheckinDisabled];
    [[API sharedAPI] initLocations];
    
    friends = [[NSMutableArray alloc] init];
    selectedFbids = [[NSMutableSet alloc] init];
    
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
    
    [locationView setBackgroundColor:[UIColor clearColor]];
    [areaView setBackgroundColor:[UIColor clearColor]];
    
    locationView.clipsToBounds = NO;
    
    locationView.adjustsFontSizeToFitWidth = YES;
    areaView.adjustsFontSizeToFitWidth = YES;
    
    [locationView setTextAlignment:NSTextAlignmentCenter];
    [areaView setTextAlignment:NSTextAlignmentCenter];
    
    [locationView setFont:[UIFont systemFontOfSize:20]];
    [areaView setFont:[UIFont systemFontOfSize:14]];
    
    [locationView setTextColor:[UIColor whiteColor]];
    [areaView setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.7]];
    
    [titleView addSubview:locationView];
    [titleView addSubview:areaView];
    
    [locationView setText:@"Flawk"];
    [areaView setText:@"locating..."];
    
    [tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [titleView setUserInteractionEnabled:YES];
    UIButton *chooseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, titleView.frame.size.width, titleView.frame.size.height)];
    [chooseButton setBackgroundColor:[UIColor clearColor]];
    [chooseButton addTarget:self action:@selector(chooseLocation:) forControlEvents:UIControlEventTouchUpInside];
    [titleView addSubview:chooseButton];
    
    self.navigationItem.titleView = titleView;
    
    [checkinButton setAlpha:0];
    
    UIGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(checkinTapped:)];
    [checkinButton addGestureRecognizer:recognizer];
    
    [super viewDidLoad];
}


- (void)checkinTapped:(UIGestureRecognizer *)sender {
    
    // see if we have anyone selected.
    if (selectedFbids.count > 0) {
        
        // create a checkin
        [[API sharedAPI] shareLocationWithUsers:selectedFbids completion:^(BOOL success, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[error localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
                    
                } else {
                    [AudioHelper vibratePhone];
                }
                
                // clear out selection
                [selectedFbids removeAllObjects];
                
                // scroll up
                [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                
                // reload
                [tableView reloadData];
            });
        } emoji:emoji];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Flawk" message:@"Select some friends before sending!" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}



- (void)showCheckin:(NSNotification *)notif {
   // scroll down or something
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [tableView setScrollEnabled:true];
    emoji = [notif userInfo][@"emoji"];
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // determine the correct alpha value for cool friends menu
    float location = scrollView.contentOffset.y;
    float alpha = (1 - (location / 200));
    [mapCell setFriendbarAlpha:alpha];
    
    // only start showing the checkin button after you've moved 70 pixels.
    float alphaTwo = (location - 70) / 200;
    alphaTwo = alphaTwo < 0 ? 0 : (alphaTwo > 1 ? 1 : alphaTwo);
    
    [checkinButton setAlpha:alphaTwo];
    [tableView setContentInset:UIEdgeInsetsMake(0, 0, (alphaTwo > 0 ? 69 : 0), 0)];
}

- (void)hideCheckin:(id)sender {
    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [tableView setScrollEnabled:NO];
}

- (void)locationChosen:(NSNotification *)notification {
    
    NSDictionary *venue = [notification userInfo];
    
    NSDictionary *location_dict = venue[@"location"];
    
    if ([location_dict objectForKey:@"city"] && [location_dict objectForKey:@"state"]) {
        [[[API sharedAPI] this_user] setLastKnownArea:[NSString stringWithFormat:@"%@, %@", [location_dict objectForKey:@"city"], [location_dict objectForKey:@"state"]]];
    } else if ([location_dict objectForKey:@"state"]) {
        [[[API sharedAPI] this_user] setLastKnownArea:[location_dict objectForKey:@"state"]];
    } else if ([location_dict objectForKey:@"country"]) {
        [[[API sharedAPI] this_user] setLastKnownArea:[location_dict objectForKey:@"country"]];
    } else {
        [[[API sharedAPI] this_user] setLastKnownArea:@"The Earth"];\
    }
    
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
    [[API sharedAPI] loginFromViewController:self];
}



- (void)locationRequest:(NSNotification *)pushNotification {
    NSLog(@"Got location request.");
    NSDictionary *userInfo = [pushNotification userInfo];
    
    if (userInfo != nil) {
        
        NSString *senderId = [userInfo objectForKey:@"from"];
        NSString *requestId = [userInfo objectForKey:@"id"];
        Friend *friend = [Friend friendWithFacebookId:senderId];
        
        if (!locationAvailable) {
            UIAlertController *controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ wants to know where you're at! Enable locations to tell them.", [friend nickname]] message:nil preferredStyle:UIAlertControllerStyleAlert];
            [controller addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[API sharedAPI] initLocations];
                [self dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:controller animated:YES completion:nil];
            return;
        }
        
        
        
        // Found friend. Show a prompt.
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ wants to know where you're at!", [friend nickname]] message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        [controller addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            // share location
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[API sharedAPI] shareLocationWithUser:friend completion:^(BOOL success, NSError *error) {
                    if (success) {
                        NSLog(@"Location shared!");
                    } else {
                        NSLog(@"Location failed to share: %@", error);
                    }
                }];
            });
            
            
        }]];
        
        [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        
        [self presentViewController:controller animated:YES completion:^{
            // Delete the location request
            [self removeLocationRequestWithId:requestId];
        }];
    }
}

- (void)removeLocationRequestWithId:(NSString *)requestId {
    [[[[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[[API sharedAPI] firebase].authData.uid] childByAppendingPath:@"location_requests"] childByAppendingPath:requestId] removeValueWithCompletionBlock:^(NSError *error, Firebase *ref) {
        if (error == nil) {
            NSLog(@"[API] Successfully dequeued friend request.");
        } else {
            NSLog(@"[API] Couldn't dequeue location request.");
        }
    }];

}

- (IBAction)addFriends:(id)sender {
    [self performSegueWithIdentifier:@"AddFriendsSegue" sender:self];
}

- (void)locationAvailable:(NSNotification *)notification {
    NSLog(@"Location available! Enabling checkin.");
    locationAvailable = YES;
    [[API sharedAPI] getLocationAndAreaWithBlock:^ (BOOL success){
        if (success) {
            locationView.text = [[API sharedAPI] this_user].lastKnownLocation;
            areaView.text = [[API sharedAPI] this_user].lastKnownArea;
        } else {
            locationView.text = @"Flawk";
            areaView.text = @"locating...";
        }
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
        if (mapCell == nil) {
            // The map cell
            mapCell = [tableView dequeueReusableCellWithIdentifier:@"MapCell"];
        }
        
        [mapCell setup];
        return mapCell;
    }
    
    /* Apply friend to cell */
    Friend *f = [[[API sharedAPI] confirmedFriends] objectAtIndex:indexPath.row - 1];
    JoinMeCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JoinMeCell"];
    BOOL selected = [selectedFbids containsObject:f.fbid];
    NSLog(@"Cell selected (%d) ? : %d", (int)indexPath.row-1, selected);
    dispatch_async(dispatch_get_main_queue(), ^{
        [cell applyFriend:f selected:selected];
    });
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[API sharedAPI] confirmedFriends] count] + 1;
}


- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        return;
    }
    
    Friend *f = [[[API sharedAPI] confirmedFriends] objectAtIndex:indexPath.row-1];
    
    JoinMeCell *cell = (JoinMeCell *)[table cellForRowAtIndexPath:indexPath];
    
    [cell setSelected:![selectedFbids containsObject:f.fbid]];
    
    if ([selectedFbids count] == 0) {
        // this is the first one
        [self setCheckinButtonVisible:YES];
    }
    
    if ([selectedFbids containsObject:f.fbid]) {
        [selectedFbids removeObject:f.fbid];
    } else {
        [selectedFbids addObject:f.fbid];
    }
    
    if ([selectedFbids count] == 0) {
        // this emptied out the list.
        [self setCheckinButtonVisible:NO];
    }
    
    NSLog(@"Total number of fbids selected: %d", [selectedFbids count]);
    
    [table deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)setCheckinButtonVisible:(BOOL)visible {
    
    
    
    
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
