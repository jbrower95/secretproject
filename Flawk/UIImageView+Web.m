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
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.requestCachePolicy = NSURLRequestReturnCacheDataElseLoad;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                float oldAlpha = [self alpha];
                [self setAlpha:0];
                [self setImage:image];
                [UIView animateWithDuration:.8 animations:^{
                    [self setAlpha:oldAlpha];
                }];
            });
        }
    }] resume];
}

@end
