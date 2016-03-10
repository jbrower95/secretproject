//
//  MapCell.h
//  Flawk
//
//  Created by Justin Brower on 3/6/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MapCell : UITableViewCell <MKMapViewDelegate> {
    BOOL setup;
    BOOL firstUpdate;
    int selected;
    UILabel *selectedLabel;
    NSMutableArray *imageViews;
    
}
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UIScrollView *sidebar;

+ (CGFloat)preferredHeightInView:(UIView *)parent;
- (id)init;
- (void)setup;
@end
