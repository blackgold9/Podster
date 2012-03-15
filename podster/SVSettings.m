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
    NSString *deviceId = [defaults objectForKey:@"deviceId"];
    if (deviceId == nil) {
        deviceId = uuid();
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"deviceId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
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

-(BOOL)notificationsNeedSyncing
{
    return [defaults boolForKey:@"NotificationsNeedSyncing"];
}

-(void)setNotificationsNeedSyncing:(BOOL)needSyncing
{
    [defaults setBool:needSyncing forKey:@"NotificationsNeedSyncing"];
     
}

- (BOOL)premiumMode
{
    return [defaults boolForKey:@"premium"];

}


- (void)setPremiumMode:(BOOL)premiumMode
{
    if (premiumMode != [self premiumMode]) {
        NSDictionary *params = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:premiumMode] forKey:@"Premium"];
        [FlurryAnalytics logEvent:@"PremiumChanged" withParameters:params];
        LOG_GENERAL(2, @"Premium changed: %@", premiumMode ? @"ON" : @"OFF");
        [defaults setBool:premiumMode forKey:@"premium"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SVPremiumModeChanged" object:self];
        
    }


}

- (NSInteger)maxNonPremiumNotifications
{
    return MAX(3, [defaults integerForKey:@"MaxNonPremiumNotifications"]);
}

- (void)setMaxNonPremiumNotifications:(NSInteger)maxNotifications
{
    [defaults setInteger:maxNotifications forKey:@"MaxNonPremiumNotifications"];
}

- (BOOL)firstRun
{
    return ![defaults boolForKey:@"SVHasRun"];
}

- (void)setFirstRun:(BOOL)firstRun
{
    [defaults setBool:!firstRun forKey:@"SVHasRun"];
}

@end
