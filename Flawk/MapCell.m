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
#import "UIImageView+Web.h"

@implementation MapCell

@synthesize mapView;

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    // Maintain a certain aspect ratio
    float ratio = 250 / 320.0f;
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


- (void)awakeFromNib {
    //Changes done directly here, we have an object
    setup = NO;
    firstUpdate = YES;
}

- (void)setup {
    if (setup) {
        return;
    }
    
    [self.mapView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCheckins:) name:@"ReloadCheckins" object:nil];
    setup = YES;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if (![annotation isKindOfClass:[MKPointAnnotation class]]) {
        return nil;
    }
    
    const NSInteger SIZE = 40;
    
    MKAnnotationView *view = [[MKAnnotationView alloc] initWithFrame:CGRectMake(0,0,SIZE,SIZE)];
    
    view.canShowCallout = YES;
    view.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SIZE, SIZE)];
    [imageView.layer setCornerRadius:SIZE/2.0];
    [imageView.layer setMasksToBounds:YES];
    
    [view addSubview:imageView];
    
    NSString *title = [annotation title];
    for (PersistentCheckin *checkin in [[API sharedAPI] checkins]) {
        if ([[checkin user].name isEqualToString:title]) {
            [[checkin user] loadFacebookProfilePictureUrlWithBlock:^(NSString *url) {
                [imageView loadRemoteUrl:url];
            }];
        }
    }
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in views)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    
    if (firstUpdate) {
        mapRegion.span.latitudeDelta = 0.02;
        mapRegion.span.longitudeDelta = 0.02;
    } else {
        mapRegion.span.latitudeDelta = [self.mapView region].span.latitudeDelta;
        mapRegion.span.longitudeDelta = [self.mapView region].span.longitudeDelta;
    }
    
    firstUpdate = NO;
    
    [self.mapView setRegion:mapRegion animated: YES];
}

@end
