//
//  MapCell.h
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapCell : UITableViewCell <MKMapViewDelegate>
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
+ (CGFloat)preferredHeightInView:(UIView *)parent;
- (id)init;
- (void)setup;
@end
