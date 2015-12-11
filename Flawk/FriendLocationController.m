//
//  FriendLocationController.m
//  Flawk
//
//  Created by Justin Brower on 12/3/15.
//  Copyright © 2015 Big Sweet Software Projects. All rights reserved.
//

#import "FriendLocationController.h"

@interface FriendLocationController ()

@end

@implementation FriendLocationController

@synthesize map, person;

- (id)initWithFriend:(Friend *)aPerson {
    
    if (self = [super init]) {
        person = aPerson;
    }
    
    self.navigationItem.title = [person name];
    
    return self;
}

- (void)viewDidLoad {
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([person lastLatitude], [person lastLongitude]);
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 800, 800);
    [map setRegion:[map regionThatFits:region] animated:YES];
    
    // Add an annotation
    MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
    point.coordinate = coordinate;
    point.title = [person name];
    point.subtitle = [person lastKnownLocation];
    
    [map addAnnotation:point];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
