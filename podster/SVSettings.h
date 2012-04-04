//
//  SVSettings.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HomeController.h"
@interface SVSettings : NSObject

- (BOOL)shouldAlwaysSubscribeToNotifications;
- (void)setShouldAlwaysSubscribeToNotifications:(BOOL)autoSubscribe;

- (BOOL)neverAutoSubscribeToNotifications;
- (void)setNeverAutoSubscribeToNotifications:(BOOL)neverSubscribe;

- (BOOL)notificationsEnabled;
- (void)setNotificationsEnabled:(BOOL)enabled;
- (HomePageScreenType)homeScreen;
- (void)setHomeScreen:(HomePageScreenType)screenType;
- (NSString *)deviceId;

+ (SVSettings *)sharedInstance;
- (NSInteger)maxFreeNotifications;
- (void)setMaxNonPremiumNotifications:(NSInteger)maxNotifications;
- (BOOL)premiumModeUnlocked;
- (BOOL)firstRun;

- (void)setFirstRun:(BOOL)firstRun;


@end
