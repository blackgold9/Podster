//
//  SVAppDelegate.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BWQuincyManager.h"
#import "BWHockeyManager.h"
#import <CoreLocation/CoreLocation.h>
@interface SVAppDelegate : UIResponder <UIApplicationDelegate, BWQuincyManagerDelegate, BWHockeyManagerDelegate,CLLocationManagerDelegate>
@property (strong, nonatomic) UIWindow *window;
- (void)startListening;
- (void)stopListening;
@end
