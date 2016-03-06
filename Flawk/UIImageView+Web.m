//
//  UIImageView+Web.m
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "UIImageView+Web.h"

@implementation UIImageView (Web)

- (void)loadRemoteUrl:(NSString *)url {
    [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setImage:image];
            });
        }
    }] resume];
}

@end
