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
    NSMutableArray *selectedIndices;
    UILabel *selectedLabel;
    NSMutableArray *imageViews;
    MKCircle *flawkArea;
    MKCircleRenderer *renderer;
    
    IBOutlet UIView *checkinView;
    
    IBOutlet UIView *emojis;
    
    BOOL dragging;
    
    IBOutlet UILabel *buttonOne;
    IBOutlet UILabel *buttonTwo;
    IBOutlet UILabel *buttonThree;
    IBOutlet UILabel *buttonFour;
    IBOutlet UILabel *buttonFive;
    
    NSString *emoji;
    
}
@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) IBOutlet UIScrollView *sidebar;

- (void)setFriendbarAlpha:(float)alpha;

+ (CGFloat)preferredHeightInView:(UIView *)parent;
- (id)init;
- (void)setup;
@end
