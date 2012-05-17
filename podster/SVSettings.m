//
//  SVSettings.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSettings.h"
#import "HomeController.h"
#import "BlockAlertView.h"
#import "Lockbox.h"

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


}

- (BOOL)neverAutoSubscribeToNotifications
{
    return [defaults boolForKey:kNeverAutoSubscribeToNotifications];
}

- (void)setNeverAutoSubscribeToNotifications:(BOOL)neverSubscribe
{
    [defaults setBool:neverSubscribe
               forKey:kNeverAutoSubscribeToNotifications];


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
    NSString *deviceId = [Lockbox stringForKey:@"deviceId"];
    if (deviceId == nil) {
        // If device id is nil, read it from the user defaults (affects v1 users)
        deviceId = [defaults stringForKey:@"deviceId"];
        if (deviceId == nil) {
            //if it's STILL nil, make a new one
            deviceId = uuid();
            [Lockbox setString:deviceId forKey:@"deviceId"];
        }
    }

    return deviceId;
}
- (void)save
{
    [defaults synchronize];
}
- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(save) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
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
     
}

- (BOOL)premiumModeUnlocked
{
    return [defaults boolForKey:@"net.vanterpool.podster.notifications"];
}

- (NSInteger)maxFreeNotifications
{
    return MAX(3, [defaults integerForKey:@"MaxFreeNotifications"]);
}

- (void)setMaxNonPremiumNotifications:(NSInteger)maxNotifications
{
    [defaults setInteger:maxNotifications forKey:@"MaxFreeNotifications"];
}

- (BOOL)firstRun
{
    return ![defaults boolForKey:@"SVHasRun"];
}

- (void)setFirstRun:(BOOL)firstRun
{
    [defaults setBool:!firstRun forKey:@"SVHasRun"];
}

- (BOOL)downloadOn3g
{
    return [defaults boolForKey:@"SVDownloadOn3g"];
}

- (void)setDownloadOn3g:(BOOL )shouldDownload
{
    [defaults setBool:shouldDownload forKey:@"SVDownloadOn3g"];
}

@end
