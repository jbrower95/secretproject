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
#import "FriendLocationController.h"
#import "FeatureConfig.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize manager;
- (void)viewDidLoad {
    
    // Register for API notifications here.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshFailed:) name:API_REFRESH_FAILED_EVENT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSuccess:) name:API_REFRESH_SUCCESS_EVENT object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parseFailure:) name:@"ParseFailure" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(parseSuccess:) name:@"ParseSuccess" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(whereAtRequest:) name:@"WhereAtRequest" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationRequest:) name:@"LocationRequest" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forgetRequest:) name:@"ForgetRequest" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acknowledgeRequest:) name:@"AcknowledgeRequest" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAvailable:) name:@"LocationAvailable" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:@"MessageReceived" object:nil];
    
    self.navigationItem.title = @"Flawk";
    
    refreshControl = [UIRefreshControl new];
    [refreshControl addTarget:self action:@selector(reloadTable:) forControlEvents:UIControlEventValueChanged];
    [tableView addSubview:refreshControl];
    [tableView sendSubviewToBack:refreshControl];
    
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
    
    [super viewDidLoad];
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
    
    [[API sharedAPI] getLocationAndAreaWithBlock:^{
        NSString *location = [[API sharedAPI] this_user].lastKnownLocation;
        NSString *area = [[API sharedAPI] this_user].lastKnownLocation;
    }];
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

- (void)whereAtRequest:(NSNotification *)friendRequest {
    NSDictionary *info = [friendRequest userInfo];
    
    Friend *f = [[Friend alloc] initWithName:[info objectForKey:@"username"] fbId:[info objectForKey:@"facebookId"]];
    
    if (f != nil) {
        [[API sharedAPI] requestWhereAt:f];
    }
}

- (void)acknowledgeRequest:(NSNotification *)pushNotification {
    NSDictionary *userInfo = [pushNotification userInfo];
    
    // parse the information that we received
    CGFloat lon = [[userInfo objectForKey:@"lon"] floatValue];
    CGFloat lat = [[userInfo objectForKey:@"lat"] floatValue];
    
    NSString *location = [userInfo objectForKey:@"location"];
    NSString *area = [userInfo objectForKey:@"area"];
    
    NSString *fbId = [userInfo objectForKey:@"from"];
    
    for (Friend *friend in [[API sharedAPI] friends]) {
        if ([fbId isEqualToString:[friend fbid]]) {
            [friend setLastLocation:CGPointMake(lon, lat) place:location area:area];
            [[API sharedAPI] save];
            break;
        }
    }
    
    [tableView reloadData];
}


- (void)locationRequest:(NSNotification *)pushNotification {
    NSLog(@"Got location request.");
    NSDictionary *userInfo = [pushNotification userInfo];
    
    if (userInfo != nil) {
        
        NSString *senderId = [userInfo objectForKey:@"from"];
        
        for (Friend *friend in [[API sharedAPI] friends]) {
            if ([senderId isEqualToString:[friend fbid]]) {
                // Found friend. Show a prompt.
                UIAlertController *controller = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ wants to know where you're at!", [friend name]] message:nil preferredStyle:UIAlertControllerStyleAlert];
                
                [controller addAction:[UIAlertAction actionWithTitle:@"Share" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // share location
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[API sharedAPI] getLocationAndAreaWithBlock:^{
                            [[API sharedAPI] shareLocationWithUser:friend];
                        }];
                    });
                    
                    
                }]];
                
                [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                
                
                [self presentViewController:controller animated:YES completion:nil];
            }
        }
        
    }    
}

- (IBAction)addFriends:(id)sender {
    
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
    
}

- (void)locationAvailable:(NSNotification *)notification {
    NSLog(@"Location available! Enabling checkin.");
    [button setEnabled:YES];
    [UIView animateWithDuration:2.0 animations:^{
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
        
        NSMutableArray *newFriends = [[NSMutableArray alloc] init];
        
        Firebase *friendsDb = [[[[[API sharedAPI] firebase] childByAppendingPath:@"users"] childByAppendingPath:[[API sharedAPI] firebase].authData.uid] childByAppendingPath:@"friends"];
        
        [friendsDb observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
            if (snapshot.exists) {
                for (Friend *f in receivedFriends) {
                    if ([snapshot hasChild:[f fbid]]) {
                        [newFriends addObject:f];
                    }
                }
            }
            
            // Assign new friends.
            friends = newFriends;
            dispatch_async(dispatch_get_main_queue(), ^() {
                [tableView reloadData];
                [refreshControl endRefreshing];
            });
        }];
    }];
}

- (void)parseFailure:(id)sender {
    NSLog(@"[Main] Couldn't associate with parse!");
}

- (void)parseSuccess:(id)sender {
    
    NSLog(@"[Main] Successfully associated with parse!");
    
}


- (void)viewWillLayoutSubviews {
    
    // Arrange our views here.
    
    
}

- (IBAction)checkin:(id)sender {
    [self performSegueWithIdentifier:@"ShareLocationSegue" sender:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FriendCellTableViewCell *cell = (FriendCellTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"LocationKnownCell"];
    
    if (cell == nil) {
        cell = [[FriendCellTableViewCell alloc] init];
    }
    
    /* Apply friend to cell */
    Friend *friend = [friends objectAtIndex:indexPath.row];
    if (friend != nil) {
        // apply them
        [cell applyFriend:friend];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [friends count];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *segue = @"FriendLocationSegue";
    
    Friend *f = [friends objectAtIndex:indexPath.row];
    
    if ([f locationKnown]) {
        [self performSegueWithIdentifier:segue sender:self];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"FriendLocationSegue"]) {
             NSIndexPath *indexPath = [tableView indexPathForSelectedRow];
             FriendLocationController *destViewController = segue.destinationViewController;
             destViewController.person = [[[API sharedAPI] friends] objectAtIndex:indexPath.row];
            destViewController.navigationItem.title = [destViewController.person name];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
