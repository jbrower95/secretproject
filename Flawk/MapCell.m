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
#import "Friend.h"
#import "PersistentCheckin.h"
#import "AudioHelper.h"

@implementation MapCell

@synthesize mapView, sidebar;


const int ORIGINAL_LOCATION = 60;

+ (CGFloat)preferredHeightInView:(UIView *)parent {
    // Maintain a certain aspect ratio
    float ratio = 320.0f / 320.0f;
    return ratio * [parent frame].size.height;
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

- (void)setFriendbarAlpha:(float)alpha {
    [self.sidebar setAlpha:alpha];
    [self.sidebar setUserInteractionEnabled:alpha>0];
}

- (void)reloadCheckins:(NSNotification *)notif {
    
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        for (PersistentCheckin *checkin in [[API sharedAPI] checkins]) {
            // Add an annotation
            MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
            point.coordinate = [[checkin region] center];
            point.title = [checkin region].identifier;
            point.subtitle = [checkin name];
            [self.mapView addAnnotation:point];
        }
    
    [self reloadSidebarNotification:nil];
}


- (void)awakeFromNib {
    //Changes done directly here, we have an object
    setup = NO;
    firstUpdate = YES;
    selected = -1;
}


- (void)showCheckin:(id)sender {
    [UIView animateWithDuration:.2 animations:^{
        // show the emojis:
        [emojis setAlpha:1];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowCheckin" object:nil userInfo:@{@"emoji" : emoji}];
}

- (void)setup {
    if (setup) {
        return;
    }
    
    [self.mapView setDelegate:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCheckins:) name:@"ReloadCheckins" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSidebarNotification:) name:@"ReloadMainTable" object:nil];
    
    imageViews = [[NSMutableArray alloc] init];
    selectedIndices = [[NSMutableArray alloc] init];
    [self refreshSidebar];
    setup = YES;
    
    
    NSArray *buttons = @[buttonOne, buttonTwo, buttonThree, buttonFour, buttonFive];
    
    UIGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectedEmoji:)];
    
    for (UILabel *button in buttons) {
        [button addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectedEmoji:)]];
    }
}


- (void)selectedEmoji:(UIGestureRecognizer *)sender {
    
    NSArray *buttons = @[buttonOne, buttonTwo, buttonThree, buttonFour, buttonFive];
    
    
    UILabel *label = (UILabel *)[sender view];
    
    // get the label emoji
    emoji = [label text];
    
    // post the update and select this one
    for (UILabel *button in buttons) {
        [button setAlpha:.5];
    }
    [label setAlpha:1.0f];
    [self showCheckin:nil];
}


- (void)reloadSidebarNotification:(id)sender {
    [self refreshSidebar];
}

- (void)refreshSidebar {
    int x = 0;
    int padding = 12;
    int x_padding = 14;
    int CELL_HEIGHT = 70;
    [imageViews
     makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [imageViews removeAllObjects];
    
    int i = 0;
    for (Friend *f in [[API sharedAPI] confirmedFriends]) {
    
        UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(x + padding, padding, CELL_HEIGHT - padding, CELL_HEIGHT - padding)];
        image.layer.masksToBounds = YES;
        image.layer.cornerRadius = 5;
        [self.sidebar addSubview:image];
        [imageViews addObject:image];
        [f loadFacebookProfilePictureUrlWithBlock:^(NSString *url) {
            [image loadRemoteUrl:url];
        }];
        
        int padding = 1;
        UILabel *initial = [[UILabel alloc] initWithFrame:CGRectMake(padding, padding, image.frame.size.width - padding, image.frame.size.height - padding)];
        [initial setTextAlignment:NSTextAlignmentCenter];
        [initial setTextColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:.7]];
        [initial setFont:[UIFont boldSystemFontOfSize:20]];
        [initial setText:[NSString stringWithFormat:@"%c", [[[f name] uppercaseString] characterAtIndex:0]]];
        [initial setAdjustsFontSizeToFitWidth:YES];
        [image addSubview:initial];
        
        [image setTag:[f fbid].longLongValue];
        [image setUserInteractionEnabled:YES];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
        [doubleTap setNumberOfTapsRequired:1];
        [image addGestureRecognizer:doubleTap];
        [image.layer setValue:[NSNumber numberWithInt:i] forKey:@"imageId"];
        
        // Add double tap recognizer
        UILongPressGestureRecognizer *r = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(imageLongPressed:)];
        [image addGestureRecognizer:r];
        x = x + CELL_HEIGHT + x_padding;
        i++;
    }
}

- (void)refreshSidebarSelections {
    int i = 0;
    
    for (UIImageView *imageView in imageViews) {
        if ([selectedIndices containsObject:[NSNumber numberWithInt:i]]) {
            [imageView setAlpha:.4];
        } else {
            [imageView setAlpha:1];
        }
        i++;
    }
}

- (void)imageTapped:(id)sender {
    UIImageView *view = (UIImageView *)[(UITapGestureRecognizer *)sender view];
    NSString *fbid = [NSString stringWithFormat:@"%ld",(long)[view tag]];
    
    Friend *friend = [Friend friendWithFacebookId:fbid];
    
    if (![friend locationKnown]) {
        
        if ([[NSUserDefaults standardUserDefaults] objectForKey:@"FirstTapTutorial"] == nil) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Hmmm" message:[NSString stringWithFormat:@"Press and hold to request %@'s location!", [friend nickname]] preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cool, I guess." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[[self window] rootViewController] dismissViewControllerAnimated:YES completion:nil];
                [self wiggleView:view];
            }]];
            
            [[[self window] rootViewController] presentViewController:alert animated:YES completion:nil];
            [[NSUserDefaults standardUserDefaults] setObject:@"Okay" forKey:@"FirstTapTutorial"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            [self wiggleView:view];
        }
        
        return;
    }
    
    int newSelected = [[view.layer valueForKey:@"imageId"] intValue];
    if ([selectedIndices containsObject:[NSNumber numberWithInt:newSelected]]) {
        [selectedIndices removeObject:[NSNumber numberWithInt:newSelected]];
        if ([selectedIndices count] == 0) {
            [self zoomToFitAnnotationsAndUser];
        } else {
            [self zoomToFitSelectedAnnotations];
        }
    } else {
        [selectedIndices addObject:[NSNumber numberWithInt:newSelected]];
        [self zoomToFitSelectedAnnotations];
    }
    
    [self refreshSidebarSelections];
}

- (void)wiggleView:(UIView *)view {
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"position.y";
    animation.values = @[ @0, @8, @-8, @4, @0 ];
    animation.keyTimes = @[ @0, @(1 / 6.0), @(3 / 6.0), @(5 / 6.0), @1 ];
    animation.duration = 0.4;
    animation.additive = YES;
    [view.layer addAnimation:animation forKey:@"wiggle"];
}

- (void)imageLongPressed:(id)sender {
    UILongPressGestureRecognizer *recognizer = (UILongPressGestureRecognizer *)sender;
    if (recognizer.state == UIGestureRecognizerStateBegan){
        NSLog(@"Ay");
        UIImageView *view = (UIImageView *)[(UITapGestureRecognizer *)sender view];
        NSString *fbid = [NSString stringWithFormat:@"%ld",(long)[view tag]];
        [recognizer setEnabled:NO];
        Friend *friend = [Friend friendWithFacebookId:fbid];
        [[API sharedAPI] requestWhereAt:friend completion:^{
            [recognizer setEnabled:YES];
            dispatch_async(dispatch_get_main_queue(), ^{
                [AudioHelper vibratePhone];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:[NSString stringWithFormat:@"Requested %@'s location.", [friend nickname]] preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [[[self window] rootViewController] dismissViewControllerAnimated:YES completion:nil];
                }]];
                [[[self window] rootViewController] presentViewController:alert animated:YES completion:nil];
            });
        }];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[API sharedAPI] confirmedFriends].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if (![annotation isKindOfClass:[MKPointAnnotation class]]) {
        return nil;
    }
    
    const NSInteger SIZE = 50;
    
    MKAnnotationView *view = [[MKAnnotationView alloc] initWithFrame:CGRectMake(0,0,SIZE,SIZE)];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, SIZE, SIZE)];
    [imageView.layer setCornerRadius:SIZE/2.0];
    [imageView.layer setMasksToBounds:YES];
    
    view.canShowCallout = YES;
    
    [view addSubview:imageView];
    
    NSString *title = [annotation title];
    for (PersistentCheckin *checkin in [[API sharedAPI] checkins]) {
        if ([[checkin user].name isEqualToString:title]) {
            UILabel *timeout = [[UILabel alloc] initWithFrame:imageView.frame];
            [timeout setFont:[UIFont boldSystemFontOfSize:16]];
            [timeout setTextColor:[UIColor whiteColor]];
            [timeout setTextAlignment:NSTextAlignmentCenter];
            [timeout setText:[[NSDate date] prettifiedStringAbbreviationFromReferenceDate:[NSDate dateWithTimeIntervalSince1970:checkin.timestamp]]];
            [imageView addSubview:timeout];
            
            [[checkin user] loadFacebookProfilePictureUrlWithBlock:^(NSString *url) {
                [imageView loadRemoteUrl:url];
            }];
        }
    }
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
    [self zoomToFitAnnotationsAndUser];
}

- (void)zoomToFitSelectedAnnotations {
    MKMapRect zoomRect = MKMapRectNull;
    
    const CGFloat leeway = 800;
    
    int numFriends = 0;
    
    MKMapPoint locations[selectedIndices.count+1];

    for (NSNumber *index in selectedIndices) {
        Friend *friend = [[API sharedAPI] confirmedFriends][index.intValue];
        if ([friend locationKnown]) {
            for (id <MKAnnotation> annotation in self.mapView.annotations) {
                if ([[annotation title] isEqualToString:[friend name]]) {
                    MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
                    locations[numFriends++] = annotationPoint;
                    MKMapRect pointRect = MKMapRectMake(annotationPoint.x - (leeway / 2), annotationPoint.y - (leeway / 2), leeway, leeway);
                    zoomRect = MKMapRectUnion(zoomRect, pointRect);
                    break;
                }
            }
        }
    }
    
    if (!MKMapRectEqualToRect(zoomRect, MKMapRectNull)) {
        [self.mapView setVisibleMapRect:zoomRect animated:YES];
    }
}

- (void)zoomToFitAnnotationsAndUser {
    MKMapRect zoomRect = MKMapRectNull;
    
    const CGFloat leeway = 800;
    
    CLLocation *userLocation = self.mapView.userLocation.location;
    
    if (userLocation != nil && !(userLocation.coordinate.latitude == 0 && userLocation.coordinate.longitude == 0)) {
        MKMapPoint point = MKMapPointForCoordinate(userLocation.coordinate);
        zoomRect = MKMapRectMake(point.x, point.y, leeway, leeway);
    }
    
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x - (leeway / 2), annotationPoint.y - (leeway / 2), leeway, leeway);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    
    if ([selectedIndices count] > 0) {
        return;
    }
    
    return;
    
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
    
    [self.mapView setRegion:mapRegion animated: NO];
}

@end
