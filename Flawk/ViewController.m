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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(acknowledgeRequest:) name:@"AcknowledgeRequest" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationAvailable:) name:@"LocationAvailable" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageReceived:) name:@"MessageReceived" object:nil];
    
    
    
    self.navigationItem.title = @"Where are ü now";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Friends" style:UIBarButtonItemStylePlain target:self action:@selector(addFriends:)];
    
    /* Check if we're logged in */
    if (![[API sharedAPI] isLoggedIn]) {
        NSLog(@"Attempting to log in user...");
        [self login];
    } else {
        NSLog(@"User is logged in already!");
        [[API sharedAPI] refreshFacebookLogin];
        [self loadAllFriends];
    }
    
    [button setEnabled:NO];
    [button setBackgroundColor:[UIColor colorWithRed:5/255.0f green:26/255.0f blue:41/255.0f alpha:.46f]];
    
    [self startStandardUpdates];
    
    [super viewDidLoad];
}

- (void)startStandardUpdates
{
    NSLog(@"[Main] Location services enabled?: %d", [CLLocationManager locationServicesEnabled]);
    
    // Create the location manager if this object does not
    // already have one.
    if (nil == manager) {
        manager = [[CLLocationManager alloc] init];
    }
    
    manager.delegate = [API sharedAPI];
    manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    
    // Set a movement threshold for new events.
    manager.distanceFilter = 100; // meters
    
    if ([manager respondsToSelector:@selector(requestAlwaysAuthorization)]){
        [manager requestAlwaysAuthorization];
    }
    
    [manager startUpdatingLocation];
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
             NSLog(@"Getting name with graph request..");
             
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
                        [self shareLocationWithUser:friend];
                    });
                    
                    
                }]];
                
                [controller addAction:[UIAlertAction actionWithTitle:@"Later" style:UIAlertActionStyleCancel handler:nil]];
                
                
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

- (void)shareLocationWithUser:(Friend *)friend {
    
    NSURLSessionConfiguration *sessionConfig =
    [NSURLSessionConfiguration defaultSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    sessionConfig.timeoutIntervalForRequest = 30.0;
    sessionConfig.timeoutIntervalForResource = 60.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    Friend *me = [[API sharedAPI] this_user];
    
    const NSString *client_id = @"EGO1P4OIQGZS0EQZ5KIIW55OV3EEN03RCMHSBHU0GUVQZ345";
    const NSString *client_sec = @"E3LEBSPKBUYCFAWH0KTDH0XIEGA0LD01XJBRCR5UKIH2ZR4P";
    
    NSString *venueURL = [NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/search?ll=%.9f,%.9f&limit=5&intent=checkin&client_id=%@&client_secret=%@&v=20151203&m=foursquare", [me lastLatitude], [me lastLongitude], client_id, client_sec];
    
    NSLog(@"Hitting venue url:");
    NSLog(@"%@", venueURL);
    
    NSURLSession *session =
    [NSURLSession sessionWithConfiguration:sessionConfig
                                  delegate:self
                             delegateQueue:nil];
    
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:[NSURL URLWithString:venueURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       
        if (data != nil) {
            NSError *e;
            NSDictionary *response = [NSJSONSerialization JSONObjectWithData:data options:NULL error:&e];
            
            if (response != nil) {
                NSLog(@"%@", response);
                NSArray *venues = (NSArray *)[(NSDictionary *)[response objectForKey:@"response"] objectForKey:@"venues"];
                NSDictionary *bestVenue = [venues objectAtIndex:0];
                
                NSString *description;
                NSString *location;
                
                if (bestVenue == nil) {
                    NSLog(@"Best venue was null. Defaulting to somewhere.");
                    description = @"Somewhere?";
                    location = @"Couldn't get location.";
                } else {
                    NSLog(@"Best venue: %@", bestVenue);
                    location = [bestVenue objectForKey:@"name"];
                    NSDictionary *location_dict = [bestVenue objectForKey:@"location"];
                    description = [NSString stringWithFormat:@"%@, %@", [location_dict objectForKey:@"city"], [location_dict objectForKey:@"state"]];
                }
                
                NSLog(@"[API] Setting area, location %@ %@", description, location);
                
                [[[API sharedAPI] this_user] setLastKnownArea:description];
                [[[API sharedAPI] this_user] setLastKnownLocation:location];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[API sharedAPI] shareLocationWithUser:friend];
                });
            }
        }
        
    }];
    [dataTask resume];
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
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
