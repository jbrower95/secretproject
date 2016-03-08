//
//  AudioHelper.m
//  Flawk
//
//  Created by Justin Brower on 3/8/16.
//  Copyright © 2016 Big Sweet Software Projects. All rights reserved.
//

#import "AudioHelper.h"

@implementation AudioHelper

+ (void)vibratePhone {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

@end
