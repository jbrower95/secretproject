//
//  MapCell.m
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "MapCell.h"

@implementation MapCell

@synthesize mapView;

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    // Maintain a certain aspect ratio
    float ratio = 210 / 320.0f;
    return ratio * [parent frame].size.width;
}

- (id)init {
    if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MapCell"]) {
        [self.mapView setShowsUserLocation:YES];
    }
    
    return self;
}

- (void)setup {
    [self.mapView setDelegate:self];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.02;
    mapRegion.span.longitudeDelta = 0.02;
    
    [mapView setRegion:mapRegion animated: YES];
}

@end
