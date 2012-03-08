//
//  SVAppDelegate.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVAppDelegate.h"
#import "UIColor+Hex.h"
#import "SVDownloadManager.h"
#import "SVPodcatcherClient.h"
#import "BWHockeyManager.h"
#import "BWQuincyManager.h"
#import <AVFoundation/AVFoundation.h>
#import "SVPlaybackManager.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcast.h"
#import "SDURLCache.h"
#import "GMGridView.h"
#import "SVSubscription.h"
#import "ZUUIRevealController.h"
#import "PodsterIAPHelper.h"
#import <CoreText/CoreText.h>

@implementation SVAppDelegate
{
    NSTimer *saveTimer;
    UIColor *backgrondTexture;
    NSManagedObjectContext *parentContext;
}

NSString *uuid();

@synthesize window = _window;
- (void)subscribeToFeedWithURL:(NSString *)url
{
    NSLog(@"Subscribing to feed with url");
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.feedURL, url];
    SVPodcast *podcast = [SVPodcast findFirstWithPredicate:pred];
    if (podcast && podcast.subscription == nil) {
        SVSubscription *sub = [SVSubscription createEntity];
        sub.podcast = podcast;
        [[NSManagedObjectContext defaultContext] save:nil];        

        [[SVPodcatcherClient sharedInstance] notifyOfSubscriptionToFeed:url
                                                           withDeviceId:[[SVSettings sharedInstance] deviceId]
                                                           onCompletion:^{
                                                               
                                                           } onError:^(NSError *error) {
                                                               
                                                           }];
    }

    
}
- (void)processLinkInPasteboard
{
    NSString *regexToReplaceRawLinks = @"(\\b(https?):\\/\\/[-A-Z0-9+&@#\\/%?=~_|!:,.;]*[-A-Z0-9+&@#\\/%=~_|])";   
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexToReplaceRawLinks
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSString *lastURLAskedAbout = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastPastebordImportURL"];
    NSString *sourceString = [UIPasteboard generalPasteboard].string;
    if ([sourceString isEqualToString:lastURLAskedAbout]) {
        // We already asked the user about this url.
        return;
    } else {
        // Save it so we don't ask them again
        [[NSUserDefaults standardUserDefaults] setValue:sourceString forKey:@"lastPastebordImportURL"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    if (sourceString) {
        NSRange range = [regex rangeOfFirstMatchInString:sourceString
                                                 options:NSRegularExpressionCaseInsensitive
                                                   range:NSMakeRange(0, [sourceString length])];
        if (range.location != NSNotFound){
            NSString *url = [sourceString substringWithRange:range];
            url = [url lowercaseString];
            UIAlertView *testView = [UIAlertView alertViewWithTitle:@"Add this feed?" message:[NSString stringWithFormat:@"We noticed you have the url: \"%@\" in your pasteboard. Would you like to subscribe to it?", url]];
            [testView addButtonWithTitle:@"Yes" handler:^{
                [[SVPodcatcherClient sharedInstance] findFeedFromLink:url
                                                         onCompletion:^(NSString *feedURL) {
                                                             if (feedURL){
                                                             [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcastWithFeedURL:feedURL
                                                                                                                      withLowerPriority:NO
                                                                                                                              inContext:[NSManagedObjectContext defaultContext]
                                                                                                                           onCompletion:^{
                                                                                                                               [self subscribeToFeedWithURL:feedURL];
                                                                                                                           } onError:^(NSError *error) {
                                                                                                                               
                                                                                                                               // The feed could not be parsed
                                                                                                                               [UIAlertView showAlertViewWithTitle:@"Whoops!"
                                                                                                                                                           message:@"The url you supplied doesn't seem to be a podcast feed. Try another url if you have one." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *view, NSInteger index) {
                                                                                                                                                               
                                                                                                                                                           }];
                                                                                                                               
                                                                                                                           }];
                                                             } else {
                                                                 // The feed could not be parsed
                                                                 [UIAlertView showAlertViewWithTitle:@"Whoops!"
                                                                                             message:@"The url you supplied doesn't seem to be a podcast feed. Try another url if you have one." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *view, NSInteger index) {
                                                                                                 
                                                                                             }];
                                                             }
                                                         } onError:^(NSError *error) {
                                                             // The feed could not be parsed
                                                             [UIAlertView showAlertViewWithTitle:@"Whoops!"
                                                                                         message:@"The url you supplied doesn't seem to be a podcast feed. Try another url if you have one." cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *view, NSInteger index) {
                                                                                             
                                                                                         }];

                                                         }];
            }];
            [testView addButtonWithTitle:@"No" handler:^{ LOG_GENERAL(2, @"Improting a feed failed"); }];
            [testView show];
        }
    }
    
}
-(void)handleCoreDataError:(NSError *)error
{
    LOG_GENERAL(0, @"Core data error: %@", error);
}
- (void)configureTheming
{
    backgrondTexture =[UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];
    UIColor *colorOne = [UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1.0]; // [UIColor colorWithHex:0x1E1E27];
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
   
   // [[GMGridView appearance] setBackgroundColor:backgrondTexture];
   // [[UIScrollView appearance] setBackgroundColor:backgrondTexture];
    //[[UIScrollView appearance] setBackgroundColor:backgrondTexture];
   // NSDictionary *navTextProperties = [NSDictionary dictionaryWithObject:colorFour
   //                                                               forKey:UITextAttributeTextColor];
   // [[UINavigationBar appearance] setTitleTextAttributes:navTextProperties];
    [[UISearchBar appearance] setBarStyle:UIBarStyleBlack];
    
    
    UIImage *barButton = [[UIImage imageNamed:@"nav-bar-btn.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 5, 5, 5)];
    
    [[UIBarButtonItem appearance] setBackgroundImage:barButton forState:UIControlStateNormal 
                                          barMetrics:UIBarMetricsDefault];
    
    UIImage *backButton = [UIImage imageNamed:@"back-btn-big.png"];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButton forState:UIControlStateNormal 
                                                    barMetrics:UIBarMetricsDefault];
    
    UIImage *minImage = [UIImage imageNamed:@"slider-fill.png"];
    //UIImage *maxImage = [UIImage imageNamed:@"slider-bg.png"];
    UIImage *thumbImage = [UIImage imageNamed:@"slider-cap.png"];
    
    
    [[UISlider appearance] setMinimumTrackImage:minImage 
                                       forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage 
                                forState:UIControlStateNormal];

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
#if defined (CONFIGURATION_Ad_Hoc)
    [[BWHockeyManager sharedHockeyManager] setAlwaysShowUpdateReminder:YES];
    [[BWHockeyManager sharedHockeyManager] setAppIdentifier:@"587e7ffe1fa052cc37e3ba449ecf426e"];
    [[BWQuincyManager sharedQuincyManager] setAppIdentifier:@"587e7ffe1fa052cc37e3ba449ecf426e"];
    [[BWQuincyManager sharedQuincyManager] setAutoSubmitCrashReport:YES];
    [[BWQuincyManager sharedQuincyManager] setAutoSubmitDeviceUDID:YES];
    [FlurryAnalytics startSession:@"FGIFUZFEUSAMC74URBVL"];
    [FlurryAnalytics setSecureTransportEnabled:YES];

    [FlurryAnalytics setUserID:[[SVSettings sharedInstance] deviceId]];

#endif
//    double delayInSeconds = 5.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
//            [self initializeCoreText];        
//        });
//    });

    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[PodsterIAPHelper sharedInstance]];
    

    [[PodsterIAPHelper sharedInstance] requestProducts];
    [MagicalRecordHelpers setupAutoMigratingCoreDataStack];
    parentContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    parentContext.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    childContext.parentContext = parentContext;
    [NSManagedObjectContext setDefaultContext:childContext];
    
    [MagicalRecordHelpers setErrorHandlerTarget:self action:@selector(handleCoreDataError:)];
    [self startSaveTimer];
    SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024   // 1MB mem cache
                                                         diskCapacity:1024*1024*50 // 50MB disk cache
                                                             diskPath:[SDURLCache defaultCachePath]];
    [NSURLCache setSharedURLCache:urlCache];
    //[[SVDownloadManager sharedInstance] resumeDownloads];
    [self configureTheming];


    // Actually register
#ifndef CONFIGURATION_Debug
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert|
                                                                           UIRemoteNotificationTypeBadge|
                                                                           UIRemoteNotificationTypeSound)];
#endif
 //   #endif
    return YES;
}


- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {

    NSString *deviceId = [[SVSettings sharedInstance] deviceId];

    NSString * tokenAsString = [[[devToken description] 
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] 
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
#ifndef CONFIGURATION_Release
    LOG_NETWORK(2, @"Notification Token: %@", tokenAsString);
#endif
    [[NSUserDefaults standardUserDefaults] setObject:tokenAsString forKey:@"notificationsToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[SVPodcatcherClient sharedInstance] registerForPushNotificationsWithToken:tokenAsString 
                                                            andDeviceIdentifer:deviceId
                                                                  onCompletion:^{
                                                                      LOG_GENERAL(2, @"Registered for notifications with podstore");    
                                                                      [[SVSettings sharedInstance] setNotificationsEnabled:YES];

                                                                  } onError:^(NSError *error) {
        [FlurryAnalytics logError:@"NotificationRegistrationFailed"
                          message:[error localizedDescription]
                            error:error];
        LOG_GENERAL(2, @"Registered for notifications with podstore failed with error: %@", error);
    }]; // custom method
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if (application.applicationState != UIApplicationStateActive) {
        NSString *hash= [userInfo valueForKey:@"url_hash"];
        LOG_GENERAL(2, @"launched for podcast with URL Hash: %@", hash);
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.urlHash, hash];
        SVPodcast *podcast = [SVPodcast findFirstWithPredicate:predicate];
        if (podcast) {
            NSDictionary *params = [NSDictionary dictionaryWithObject:podcast.title
                                                               forKey:@"Title"];
            [FlurryAnalytics logEvent:@"LaunchedFromNotification"
                       withParameters:params];

            SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
            controller.podcast = podcast;
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                UINavigationController *nav = (UINavigationController *)self.window.rootViewController;
                [nav pushViewController:controller animated:YES];

            });
        }
    }
}
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    LOG_GENERAL(1,@"Error registering for notifications. Error: %@", err);
#ifndef CONFIGURATION_Release
//  [UIAlertView showAlertViewWithTitle:@"Error" message:@"Could not register for notifications" cancelButtonTitle:@"OK" otherButtonTitles:nil
//                              
//                              handler:^(UIAlertView *view, NSInteger index) {
//                                  
//                              }];
#endif
}
	
- (void)applicationWillResignActive:(UIApplication *)application
{
    [[NSManagedObjectContext defaultContext] save:nil];
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[NSManagedObjectContext defaultContext] save:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
//        [self performSelectorOnMainThread:@selector(processLinkInPasteboard) withObject:self waitUntilDone:NO];
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
#pragma mark - remote control
-(void)startListening
{
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

-(void)stopListening
{
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
}
-(BOOL)canBecomeFirstResponder
{
    return YES;
}
- (void) remoteControlReceivedWithEvent: (UIEvent *) receivedEvent {
    AVPlayer *_player = [[SVPlaybackManager sharedInstance] player];
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlStop:
            case UIEventSubtypeRemoteControlPause:
                if( _player) {
                    _player.rate = 0;
                }
                break;
            case UIEventSubtypeRemoteControlPlay:
                if(_player) {
                    _player.rate = 1;
                }
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                if( _player) {
                    if ( _player.rate != 0) {
                        _player.rate = 0;
                    } else {
                        _player.rate = 1;
                    }
                }
                break;

            default:
                break;
        }
    }
}

- (void)startSaveTimer
{
    LOG_GENERAL(2, @"Starting Save Timer");
    [self stopSaveTimer];
    
    saveTimer = [NSTimer scheduledTimerWithTimeInterval:30 // save every 30 seconds
                                                  block:^(NSTimeInterval time) {
                                                      NSManagedObjectContext *rootContext = [NSManagedObjectContext defaultContext].parentContext;
                                                      LOG_GENERAL(2, @"Checking if root save is neccesary");
                                                      if (rootContext.hasChanges) {
                                                          LOG_GENERAL(2, @"Queing Root Save");
                                                          [rootContext performBlock:^{
                                                              LOG_GENERAL(2, @"Saving root context");
                                                              [rootContext saveWithErrorHandler:^(NSError *error) {
                                                                  LOG_GENERAL(0, @"ERROR: Error saving root store. Big deal here Y'Alll" );
                                                              }];
                                                          }];                                                 
                                                      }
                                                  } 
                                                repeats:YES];
    

}

- (void)stopSaveTimer
{
    LOG_GENERAL(2, @"Stopping Save Timer");
    if(saveTimer) {
        [saveTimer invalidate];
        saveTimer = nil;
    }
}

@end
