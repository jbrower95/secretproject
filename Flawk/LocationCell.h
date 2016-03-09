//
//  LocationCell.h
//  Flawk
//
//  Created by Justin Brower on 3/9/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocationCell : UITableViewCell

@property (nonatomic, retain) IBOutlet UILabel *nameLabel;
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;
@property (nonatomic, retain) IBOutlet UILabel *distanceLabel;
@property (nonatomic, retain) IBOutlet UIImageView *iconView;



- (void)applyLocation:(NSDictionary *)location;

@end
