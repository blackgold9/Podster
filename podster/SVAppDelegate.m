//
//  SVAppDelegate.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "Appirater.h"
#import "SVAppDelegate.h"
#import "UIColor+Hex.h"
#import "SVDownloadManager.h"
#import "SVPodcatcherClient.h"
#import <AVFoundation/AVFoundation.h>
#import "SVPlaybackManager.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcast.h"
#import "SDURLCache.h"
#import "GMGridView.h"
#import "SVSubscriptionManager.h"
#import "PodsterIAPHelper.h"
#import <CoreText/CoreText.h>
#import "BannerViewController.h"
#import "MBProgressHUD.h"
#import "SVSettings.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"
#import "DDNSLoggerLogger.h"
#import "Lockbox.h"
#import <HockeySDK/HockeySDK.h>
static const int ddLogLevel = LOG_LEVEL_INFO;
@interface SVAppDelegate() <BITHockeyManagerDelegate, BITUpdateManagerDelegate, BITCrashManagerDelegate> {}
@end
@implementation SVAppDelegate
{
    DDFileLogger *fileLogger;
    BOOL isFirstRun;
    CLLocationManager *locationManager;
    NSTimer *saveTimer;
}

NSString *uuid();
@synthesize window = _window;

-(void)handleCoreDataError:(NSError *)error
{
    LOG_GENERAL(0, @"Core data error: %@", error);
}

- (void)configureTheming
{
    UIColor *colorOne = [UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1.0]; // [UIColor colorWithHex:0x1E1E27];
    //    UIColor *colorTwo = [UIColor colorWithHex:0x65F4FF];
    //    UIColor *colorThree = [UIColor colorWithHex:0x41EA29];
    //    UIColor *colorFour = [UIColor colorWithHex:0xC0C0E8];
    //
    //    UIColor *colorFive = [UIColor colorWithHex:0x000000];
    UIImage *image = [UIImage imageNamed:@"nav-bar.png"];
    [[UINavigationBar appearance] setBarStyle:UIBarStyleBlackOpaque];
    [[UINavigationBar appearance] setBackgroundImage:image forBarMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"bottom-toolbar.png"] forToolbarPosition:UIToolbarPositionBottom barMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTintColor:colorOne];
    [[UISegmentedControl appearance] setTintColor:colorOne];
    [[UIToolbar appearance] setTintColor:colorOne];
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
    [[UISlider appearance] setMaximumTrackTintColor:colorOne];
    //  [[UIProgressView appearance] setMaximumTrackTintColor:colorOne];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
#ifndef CONFIGURATION_AppStore
    [DDLog addLogger:[DDNSLoggerLogger sharedInstance]];
#endif
    fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 1; // 1 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 1;
    
    [DDLog addLogger:fileLogger];
    
    [[BITHockeyManager sharedHockeyManager] configureWithBetaIdentifier:@"587e7ffe1fa052cc37e3ba449ecf426e"
                                                         liveIdentifier:@"f36888480951c50f12bb465ab891cf24"
                                                               delegate:self];
    
    [[BITHockeyManager sharedHockeyManager] startManager];
#if defined (CONFIGURATION_AppStore)
    DDLogVerbose(@"Running in Appstore mode");
    [FlurryAnalytics startSession:@"SQ19K1VRZT84NIFMRA1S"];
    [FlurryAnalytics setSecureTransportEnabled:YES];
    //    [[BWQuincyManager sharedQuincyManager] setAppIdentifier:@"f36888480951c50f12bb465ab891cf24"];
    //    [[BWQuincyManager sharedQuincyManager] setAutoSubmitCrashReport:YES];
    //    [[BWQuincyManager sharedQuincyManager] setFeedbackActivated:YES];
    //    [[BWQuincyManager sharedQuincyManager] setDelegate:self];
    //   [[BWQuincyManager sharedQuincyManager] setFeedbackActivated:YES];
#endif
    
#if defined (CONFIGURATION_Ad_Hoc)
    DDLogVerbose(@"Running in Ad_Hoc mode");
    //    [[BWHockeyManager sharedHockeyManager] setAlwaysShowUpdateReminder:YES];
    //    [[BWHockeyManager sharedHockeyManager] setAppIdentifier:@"587e7ffe1fa052cc37e3ba449ecf426e"];
    //    [[BWQuincyManager sharedQuincyManager] setAppIdentifier:@"587e7ffe1fa052cc37e3ba449ecf426e"];
    //    [[BWQuincyManager sharedQuincyManager] setAutoSubmitCrashReport:YES];
    [FlurryAnalytics startSession:@"FGIFUZFEUSAMC74URBVL"];
    [FlurryAnalytics setSecureTransportEnabled:YES];
    //[[BWQuincyManager sharedQuincyManager] setFeedbackActivated:YES];
    [FlurryAnalytics setUserID:[[SVSettings sharedInstance] deviceId]];
    //    [[BWQuincyManager sharedQuincyManager] setDelegate:self];
    //    [[BWHockeyManager sharedHockeyManager] setDelegate:self];
#endif
    
    //    NSManagedObjectModel *model = [NSManagedObjectModel MR_managedObjectModelNamed:@"SVPodcastDatastore.momd"];
    //    [NSManagedObjectModel MR_setDefaultManagedObjectModel:model];
    
    
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"PodsterData/StoreContent/persistentStore"];
    
    isFirstRun = [[SVSettings sharedInstance] firstRun];
    SDURLCache *URLCache = [[SDURLCache alloc] initWithMemoryCapacity:1024*1024*2 diskCapacity:1024*1024*100 diskPath:[SDURLCache defaultCachePath]];
    [URLCache setIgnoreMemoryOnlyStoragePolicy:YES];
    [NSURLCache setSharedURLCache:URLCache];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:[PodsterIAPHelper sharedInstance]];
    
    [self configureTheming];
    
    
    // Actually register
#ifndef CONFIGURATION_Debug
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeAlert|
                                                                           UIRemoteNotificationTypeBadge|
                                                                           UIRemoteNotificationTypeSound)];
#else
    [self application:[UIApplication sharedApplication] didFailToRegisterForRemoteNotificationsWithError:nil];
#endif
    
    
    BannerViewController *controller = [[BannerViewController alloc] initWithContentViewController:[[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateInitialViewController]];
    self.window.rootViewController = controller;
    
    [[SVSettings sharedInstance] setFirstRun:NO];
    
    saveTimer = [NSTimer scheduledTimerWithTimeInterval:120 target:self selector:@selector(saveData) userInfo:nil repeats:YES];
    return YES;
    
}

- (void)saveData
{
    DDLogInfo(@"Saving datastore to disk.");
    //   [[NSManagedObjectContext MR_defaultContext] MR_save];
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    
    DDLogInfo(@"Successuflly got a notification token from apple");
    NSString * tokenAsString = [[[devToken description]
                                 stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]]
                                stringByReplacingOccurrencesOfString:@" " withString:@""];
#ifndef CONFIGURATION_AppStore
    DDLogInfo(@"Notification Token: %@", tokenAsString);
#endif
    [[SVSettings sharedInstance] setNotificationsEnabled:YES];
    [[NSUserDefaults standardUserDefaults] setObject:tokenAsString forKey:@"notificationsToken"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self registerWithOptionalNotificationToken:tokenAsString];
}

/* Register with service. The token is optional. We want you to register regardless */
- (void)registerWithOptionalNotificationToken:(NSString *)tokenAsString
{
    NSString *deviceId = [[SVSettings sharedInstance] deviceId];
    [[SVPodcatcherClient sharedInstance] registerWithDeviceId:deviceId
                                            notificationToken:tokenAsString
                                                 onCompletion:^(id response ){
                                                     if (isFirstRun) {
                                                         // Restore pre-existing subscriptions if they exist
                                                         NSArray *subscriptions = (NSArray *)response;
                                                         for (NSDictionary *sub in subscriptions) {
                                                             NSDictionary *subData = [sub objectForKey:@"subscription"];
                                                             [SVPodcast fetchAndSubscribeToPodcastWithId:[subData objectForKey:@"feed_id"]
                                                                                            shouldNotify:[[subData objectForKey:@"notify"] boolValue]];
                                                         }
                                                     } else {
                                                         // Reconcile subs
                                                     }
                                                     
                                                 } onError:^(NSError *error) {
                                                     [FlurryAnalytics logError:@"RegistrationFailed"
                                                                       message:[error localizedDescription]
                                                                         error:error];
                                                     LOG_GENERAL(2, @"Registering with podstore failed with error: %@", error);
                                                 }];
}



-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    
    
    if (application.applicationState != UIApplicationStateActive) {
        NSString *feedId= [userInfo valueForKey:@"feedId"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RecievedPodcastNotification" object:self userInfo:userInfo];
        DDLogInfo(@"launched for podcast with podstore id: %@", feedId);
      
    }
}
- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    [FlurryAnalytics logEvent:@"LaunchedWithNotificationsDisabled"];
    [[SVSettings sharedInstance] setNotificationsEnabled:NO];
    [self registerWithOptionalNotificationToken:nil];
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
    
    
    __block UIBackgroundTaskIdentifier background_task; //Create a task object
    
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        [application endBackgroundTask: background_task]; //Tell the system that we are done with the tasks
        background_task = UIBackgroundTaskInvalid; //Set the task to be invalid
        
        //System will be shutting down the app at any point in time now
    }];
    [FlurryAnalytics logEvent:@"SavingOnEnteringBackground" timed:YES];
    //Background tasks require you to use asynchronous tasks
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        [[NSManagedObjectContext MR_defaultContext] performBlockAndWait:^void() {
            NSArray *subscriptions= [SVPodcast MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"isSubscribed == YES"]
                                                             inContext:[NSManagedObjectContext MR_defaultContext] ];
            NSMutableArray *subscriptionData = [NSMutableArray arrayWithCapacity:subscriptions.count];
            
            for(SVPodcast *podcast in subscriptions) {
                id data = [NSDictionary dictionaryWithObjectsAndKeys:podcast.podstoreId,@"podstoreId",podcast.shouldNotify, @"shouldNotify",  nil];
                [subscriptionData addObject:data];
            }
            [Lockbox setArray:subscriptionData forKey:@"subscriptions"];
            
        }];
        [[NSManagedObjectContext MR_defaultContext] MR_saveNestedContexts];
        [FlurryAnalytics endTimedEvent:@"SavingOnEnteringBackground" withParameters:nil];
        [application endBackgroundTask: background_task]; //End the task so the system knows that you are done with what you need to perform
        background_task = UIBackgroundTaskInvalid; //Invalidate the background_task
        
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [Appirater appEnteredForeground:YES];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SVReloadData" object:nil];
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
                
                [[SVPlaybackManager sharedInstance] pause];
                
                break;
            case UIEventSubtypeRemoteControlPlay:
                
                [[SVPlaybackManager sharedInstance] play];
                
                break;
            case UIEventSubtypeRemoteControlTogglePlayPause:
                
                if ( _player.rate != 0) {
                    [[SVPlaybackManager sharedInstance] pause];
                } else {
                    [[SVPlaybackManager sharedInstance] play];
                }
                break;
            case UIEventSubtypeRemoteControlNextTrack:
                [[SVPlaybackManager sharedInstance] skipForward];
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:
                [[SVPlaybackManager sharedInstance] skipBack];
                break;
                
            default:
                break;
        }
    }
}

-(NSString *)applicationLogForCrashManager:(BITCrashManager *)crashManager
{
    NSString *output;
    if ([[fileLogger logFileManager] sortedLogFilePaths].count > 0) {
        output = [NSString stringWithContentsOfFile:[[[fileLogger logFileManager] sortedLogFilePaths] objectAtIndex:0]
                                           encoding:NSUTF8StringEncoding
                                              error:nil];
    }
    if ([output length] > 5000) {
        output = (NSMutableString *)[output substringWithRange:NSMakeRange([output length]-5000-1, 5000)];
    }
    return output;
}

- (NSString *)customDeviceIdentifierForUpdateManager:(BITUpdateManager *)updateManager {
#ifndef CONFIGURATION_AppStore
    if ([[UIDevice currentDevice] respondsToSelector:@selector(uniqueIdentifier)])
        return [[UIDevice currentDevice] performSelector:@selector(uniqueIdentifier)];
#endif
    return nil;
}



@end
