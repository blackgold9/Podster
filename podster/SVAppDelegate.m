//
//  SVAppDelegate.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVAppDelegate.h"
#import "SVGPodderClient.h"
#import "SVDownloadManager.h"
@implementation SVAppDelegate
{
    MKNetworkEngine *engine;
}

@synthesize window = _window;
-(void)handleCoreDataError:(NSError *)error
{
    LOG_GENERAL(0, @"Core data error: %@", error);
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MagicalRecordHelpers setupAutoMigratingCoreDataStack];
    [MagicalRecordHelpers setErrorHandlerTarget:self action:@selector(handleCoreDataError:)];
    [[SVDownloadManager sharedInstance] resumeDownloads];
  UIColor *colorOne = [UIColor colorWithRed:0.101 green:0.101 blue:0.101 alpha:1.0];
  UIColor *colorTwo = [UIColor colorWithRed:0.917 green:0.917 blue:0.917 alpha:1.0];
  UIColor *colorThree = [UIColor colorWithRed:0.8 green:0.792 blue:0.678 alpha:1.0];
  UIColor *colorFour = [UIColor colorWithRed:0.654 green:0.639 blue:0.494 alpha:1.0];
  UIColor *colorFive = [UIColor colorWithRed:0.007 green:0.152 blue:0.2 alpha:1.0];
  [[UINavigationBar appearance] setTintColor:colorFive];
    [[UIToolbar appearance] setTintColor:colorFive];
    [[UIBarButtonItem appearance] setTintColor:colorFive];
  NSDictionary *navTextProperties = [NSDictionary dictionaryWithObject:colorTwo
                                                                forKey:UITextAttributeTextColor];
  [[UINavigationBar appearance] setTitleTextAttributes:navTextProperties];
  [[SVGPodderClient sharedInstance] useCache];
    return YES;
}
	
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
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
