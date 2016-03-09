//
//  NSDate+Prettify.h
//  Flawk
//
//  Created by Justin Brower on 3/5/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Prettified)
- (NSString *)prettifiedStringFromReferenceDate:(NSDate *)past;
- (NSString *)prettifiedStringAbbreviationFromReferenceDate:(NSDate *)past;
@end
