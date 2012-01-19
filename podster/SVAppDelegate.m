//
//  SVAppDelegate.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVAppDelegate.h"
#import "SVGPodderClient.h"
#import "UIColor+Hex.h"
#import "SVDownloadManager.h"
#import "UIDevice+IdentifierAddition.h"
#import "SVPodcatcherClient.h"
@implementation SVAppDelegate
{
    MKNetworkEngine *engine;
}

@synthesize window = _window;
-(void)handleCoreDataError:(NSError *)error
{
    LOG_GENERAL(0, @"Core data error: %@", error);
}
- (void)configureTheming
{
    UIColor *colorOne = [UIColor colorWithHex:0x1E1E27];
    UIColor *colorTwo = [UIColor colorWithHex:0x65F4FF];
    UIColor *colorThree = [UIColor colorWithHex:0x41EA29];
    UIColor *colorFour = [UIColor colorWithHex:0xC0C0E8];
    
    UIColor *colorFive = [UIColor colorWithHex:0x000000];
        UIImage *image = [UIImage imageNamed:@"nav-bar.png"];
    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
//    [[UINavigationBar appearance] setTintColor:colorOne];
    [[UISegmentedControl appearance] setTintColor:colorOne];
    [[UIToolbar appearance] setTintColor:colorOne];
    [[UIBarButtonItem appearance] setTintColor:colorOne];

    NSDictionary *navTextProperties = [NSDictionary dictionaryWithObject:colorFour
                                                                  forKey:UITextAttributeTextColor];
   // [[UINavigationBar appearance] setTitleTextAttributes:navTextProperties];
    [[UISearchBar appearance] setBarStyle:UIBarStyleBlack];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecordHelpers setupAutoMigratingCoreDataStack];
    [MagicalRecordHelpers setErrorHandlerTarget:self action:@selector(handleCoreDataError:)];
    [[SVDownloadManager sharedInstance] resumeDownloads];
    [self configureTheming];
  [[SVGPodderClient sharedInstance] useCache];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert];
    return YES;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];  
    if (!deviceId)
    {
        deviceId = [[UIDevice currentDevice] uniqueDeviceIdentifier];
        [[NSUserDefaults standardUserDefaults] setObject:deviceId forKey:@"deviceId"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }

    NSString * tokenAsString = [[[devToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
    [[SVPodcatcherClient sharedInstance] registerForPushNotificationsWithToken:tokenAsString 
                                                            andDeviceIdentifer:deviceId
                                                                  onCompletion:^{
                                                                      LOG_GENERAL(2, @"Registered for notifications with podstore");    
                                                                      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"notificationsEnabled"];
                                                                      [[NSUserDefaults standardUserDefaults] synchronize];

                                                                  } onError:^(NSError *error) {
                                                                      LOG_GENERAL(2, @"Registered for notifications with podstore failed with error: %@", error);    
                                                                  }]; // custom method
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    LOG_GENERAL(1,@"Error in registration. Error: %@", err);
}
	
- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSManagedObjectContext defaultContext] save];
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSManagedObjectContext defaultContext] save];
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
