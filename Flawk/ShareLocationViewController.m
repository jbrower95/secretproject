//
//  ShareLocationViewController.m
//  Flawk
//
//  Created by Justin Brower on 12/5/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "ShareLocationViewController.h"
#import "API.h"
#import <CoreLocation/CoreLocation.h>
@interface ShareLocationViewController ()

@end

@implementation ShareLocationViewController

@synthesize tableView;

- (void)viewDidLoad {
    selections = [[NSMutableSet alloc] init];
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([[API sharedAPI] friends].count > 0) {
        return [[API sharedAPI] friends].count + 1;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendSelectionCell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"friendSelectionCell"];
    }
    
    
    if (indexPath.row == 0) {
        [[cell textLabel] setText:@"Everyone"];
        [[cell textLabel] setTextAlignment:NSTextAlignmentCenter];
        [[cell textLabel] setFont:[UIFont systemFontOfSize:16]];
        
        if ([selections containsObject:@"ALL"]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    } else {        
        Friend *friend = [[[API sharedAPI] friends] objectAtIndex:indexPath.row - 1];
    
        [[cell textLabel] setText:[friend name]];
    
        if ([selections containsObject:[friend fbid]] || [selections containsObject:@"ALL"]) {
            // we selected this sell
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            // nope
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *target;
    if (indexPath.row == 0) {
        target = @"ALL";
    } else {
        target = [[[[API sharedAPI] friends] objectAtIndex:indexPath.row - 1] fbid];
    }
    
    if ([selections containsObject:target]) {
        [selections removeObject:target];
    } else {
        [selections addObject:target];
    }
    
    [tableView reloadData];
}

- (IBAction)shareOnce:(id)sender {
    
    if (selections == nil || [selections count] == 0) {
        // Nothing
        return;
    }
    
    if ([selections containsObject:@"ALL"]) {
        [selections removeObject:@"ALL"];
        for (Friend *pal in [[API sharedAPI] friends]) {
            [selections addObject:[pal fbid]];
        }
    }
    
}

- (IBAction)shareAlways:(id)sender {
    if ([selections containsObject:@"ALL"]) {
        [selections removeObject:@"ALL"];
        for (Friend *pal in [[API sharedAPI] friends]) {
            [selections addObject:[pal fbid]];
        }
    }
    
    switch ([CLLocationManager authorizationStatus]) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [[[CLLocationManager alloc] init] requestAlwaysAuthorization];
            return;
        case kCLAuthorizationStatusAuthorizedAlways: {
            // Ready 2 go
            CLLocationCoordinate2D center = CLLocationCoordinate2DMake([[[API sharedAPI] this_user] lastLatitude], [[[API sharedAPI] this_user] lastLongitude]);
            CLRegion *geofence = [[CLCircularRegion alloc]initWithCenter:center
                                                                radius:100.0
                                                            identifier:@"Bridge"];
            return;
        }
        case kCLAuthorizationStatusDenied:
        case kCLAuthorizationStatusRestricted: {
            UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error" message:@"This requires location services -- please enable them for Flawk in Settings!" preferredStyle:UIAlertControllerStyleAlert];
            [error addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:error animated:YES completion:nil];
            return;
        }
    }
    
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
