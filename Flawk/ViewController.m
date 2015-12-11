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
#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

#import <FBSDKCoreKit/FBSDKConstants.h>

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
    
    [self setCheckinDisabled];
    [[API sharedAPI] initLocations];
    
    /* Check if we're logged in */
    if (![[API sharedAPI] isLoggedIn]) {
        NSLog(@"Attempting to log in user...");
        [self login];
    } else {
        NSLog(@"User is logged in already!");
        [[API sharedAPI] refreshFacebookLogin];
        [self loadAllFriends];
    }
    
    [super viewDidLoad];
}

- (void)setCheckinDisabled {
    [button setEnabled:NO];
    [button setBackgroundColor:[UIColor colorWithRed:5/255.0f green:26/255.0f blue:41/255.0f alpha:.46f]];
}

- (void)viewDidAppear:(BOOL)animated {
    [[API sharedAPI] getAllFriendsWithBlock:nil];
    
    if ([[[API sharedAPI] this_user] locationKnown]) {
        [self locationAvailable:nil];
    }
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
    FBSDKLoginManager *login = [[FBSDKLoginManager alloc] init];
    [login
     logInWithReadPermissions: @[@"public_profile", @"email", @"user_friends"]
     fromViewController:self
     handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
         if (error != nil || result.isCancelled) {
             NSLog(@"[Main] Cancelled");
             dispatch_async(dispatch_get_main_queue(), ^{
                 [self setCheckinDisabled];
                 [self authorizeAgain];
             });
         } else {
             NSLog(@"[Main] Logged in!");
             NSLog(@"[Main] Loading info about current user...");
             
             FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields" : @"name, email"}];
             
             [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
                  
                  if (!error) {
                      [[API sharedAPI] setLoggedInUser:result[@"name"] token:[[FBSDKAccessToken currentAccessToken] userID]];
                      
                      dispatch_async(dispatch_get_main_queue(), ^() {
                          [self refreshSuccess:nil];
                      });
                  } else {
                      dispatch_async(dispatch_get_main_queue(), ^() {
                          [self refreshFailed:nil];
                      });
                  }
              }];
         }
         
     }];
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


- (void)locationAvailable:(NSNotification *)notification {
    NSLog(@"Location available! Enabling checkin.");
    [button setEnabled:YES];
    [UIView animateWithDuration:2.0 animations:^{
        [button setBackgroundColor:[UIColor colorWithRed:31/255.0f green:140/255.0f blue:220/255.0f alpha:1]];
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
    NSSet *declinedPermissions = [[FBSDKAccessToken currentAccessToken] declinedPermissions];
    
    if ([declinedPermissions count] > 0) {
        NSLog(@"Error -- User declined permissions. App won't work properly. ");
        // TODO: Show some UI for this.
    }
    
    NSSet *permissions = [[FBSDKAccessToken currentAccessToken] permissions];
    
    /* Make yourself a parse account if you don't already have one */
    [[API sharedAPI] initParse];
    
    [self loadAllFriends];
    
}

- (void)loadAllFriends {
    [[API sharedAPI] getAllFriendsWithBlock:^(NSArray *receivedFriends, NSError *error) {
        if (error != nil) {
            NSLog(@"%@", [error localizedDescription]);
        }
        
        NSLog(@"Got %lu friends.", (unsigned long)[receivedFriends count]);
        
        dispatch_async(dispatch_get_main_queue(), ^() {
            [tableView reloadData];
        });
        
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

- (IBAction)addFriends:(id)sender {
         
    NSLog(@"Ayy");
}


- (IBAction)checkin:(id)sender {
    [self performSegueWithIdentifier:@"ShareLocationSegue" sender:nil];
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
    Friend *friend = [[[API sharedAPI] friends] objectAtIndex:indexPath.row];
    if (friend != nil) {
        // apply them
        [cell applyFriend:friend];
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[API sharedAPI] friends] count];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSString *segue = @"FriendLocationSegue";
    
    Friend *f = [[[API sharedAPI] friends] objectAtIndex:indexPath.row];
    
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
