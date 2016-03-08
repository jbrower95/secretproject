//
//  MapCell.m
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "MapCell.h"
#import "API.h"
#import "PersistentCheckin.h"
#import "NSDate+Prettify.h"

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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.mapView.showsUserLocation = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCheckins:) name:@"ReloadCheckins" object:nil];
    
    return self;
}

- (void)reloadCheckins:(NSNotification *)notif {
    
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        for (PersistentCheckin *checkin in [[API sharedAPI] checkins]) {
            // Add an annotation
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = [[checkin region] center];
            point.title = [checkin region].identifier;
            point.subtitle = [[NSDate date] prettifiedStringFromReferenceDate:[NSDate dateWithTimeIntervalSince1970:[checkin timestamp]]];
            [self.mapView addAnnotation:point];
        }
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    MKAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"loc"];
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    NSLog(@"Touched annotation!");
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(nonnull NSArray<MKAnnotationView *> *)views {
    NSLog(@"Map added %d annotation!", views.count);
}

- (void)setup {
    [self.mapView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCheckins:) name:@"ReloadCheckins" object:nil];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.02;
    mapRegion.span.longitudeDelta = 0.02;
    
    [self.mapView setRegion:mapRegion animated: YES];
}

@end
