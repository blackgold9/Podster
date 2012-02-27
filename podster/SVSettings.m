//
//  SVSettings.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSettings.h"
#import "HomeController.h"
@implementation SVSettings {
    NSUserDefaults *defaults;
}
NSString *kShouldAlwaysSubscribeToNotifications = @"shouldAlwaysSubscribeToNotifications";
NSString *kNeverAutoSubscribeToNotifications = @"neverAutoSubscribeToNotifications";
NSString *kNotificationsEnabled = @"notificationsEnabled";

NSString *uuid(){
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return uuidString;
}

- (BOOL)shouldAlwaysSubscribeToNotifications
{
    return [defaults boolForKey:kShouldAlwaysSubscribeToNotifications];
}

- (void)setShouldAlwaysSubscribeToNotifications:(BOOL)autoSubscribe
{
   [defaults setBool:autoSubscribe
              forKey:kShouldAlwaysSubscribeToNotifications];
    [defaults synchronize];

}

- (BOOL)neverAutoSubscribeToNotifications
{
    return [defaults boolForKey:kNeverAutoSubscribeToNotifications];
}

- (void)setNeverAutoSubscribeToNotifications:(BOOL)neverSubscribe
{
    [defaults setBool:neverSubscribe
               forKey:kNeverAutoSubscribeToNotifications];
    [defaults synchronize];

}

- (BOOL)notificationsEnabled
{
    return [defaults boolForKey:kNotificationsEnabled];
}

- (void)setNotificationsEnabled:(BOOL)enabled
{
    [defaults setBool:enabled
               forKey:kNotificationsEnabled];
}

- (NSString *)deviceId
{
    NSString *deviceId = [defaults objectForKey:@"deviceId"];
    if (deviceId == nil) {
        deviceId = uuid();
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"deviceId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    return deviceId;
}

+ (SVSettings *)sharedInstance
{
    static SVSettings *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SVSettings alloc] init];
        instance->defaults = [NSUserDefaults standardUserDefaults];
    });
    
    return instance;
}

- (HomePageScreenType)homeScreen
{
    NSInteger num = [defaults integerForKey:@"HomeScreenType"];
    HomePageScreenType screenType = (HomePageScreenType)num;
    return screenType;
}

- (void)setHomeScreen:(HomePageScreenType)screenType
{
    [defaults setInteger:screenType forKey:@"HomeScreenType"];
    [defaults synchronize];
}
@end
