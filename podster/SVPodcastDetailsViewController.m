//
//  SVPodcastDetailsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastDetailsViewController.h"
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "SVPodcatcherClient.h"
#import "SVPodcastEntry.h"
#import "SVPlaybackManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SVDownloadManager.h"
#import "SVPodcastSearchResult.h"
#import "ActsAsPodcast.h"
#import "MessageGenerator.h"

#import "SVEpisodeListCell.h"
#import "GTMNSString+HTML.h"
#import "SVEpisodeDetails.h"
#import "SVPlaybackManager.h"
#import "SVPlaybackController.h"
#import "SVPodcastModalView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "BlockAlertView.h"
#import "GCDiscreetNotificationView.h"
#import "SVSubscriptionManager.h"
#import "_SVPodcastEntry.h"
#import "_SVPodcast.h"
#import <Twitter/Twitter.h>
#import "MBProgressHUD.h"
#import "PodcastSettingsViewController.h"
static const int ddLogLevel = LOG_LEVEL_INFO;
@interface SVPodcastDetailsViewController () <PodcastSettingsViewControllerDelegate>


- (void)reloadData;
@end
@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    NSManagedObjectContext *localContext;
    SVPodcast *localPodcast;
    BOOL optionsOpen;
    BOOL isInitialLoad;
    BOOL isSubscribed;
    NSArray *items;
    NSManagedObjectContext *context;
    NSTimer *gracePeriodTimer;
}
@synthesize shareButton;
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize tableView = _tableView;
@synthesize metadataView;
@synthesize imageView;
@synthesize subscribeButton;
@synthesize podcast = _podcast;
@synthesize optionsButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        items = [NSArray array];
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)optionsTapped:(id)sender {
//    SVPodcastModalView *modal = [[SVPodcastModalView alloc] initWithFrame:self.view.bounds ];
//    modal.podcast = localPodcast;
//    [self.view addSubview:modal];
//    [modal showFromPoint:((UIView *)sender).center];
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"PodcastStoryboard" bundle:nil];

    PodcastSettingsViewController *controller = [board instantiateViewControllerWithIdentifier:@"PodcastSettings"];
    [localContext performBlockAndWait:^{
        controller.shouldNotify = localPodcast.shouldNotifyValue;
        controller.sortAscending = !localPodcast.sortNewestFirstValue;
        controller.downloadsToKeep = (NSUInteger) localPodcast.downloadsToKeepValue;
    }];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.delegate = self;
    [self.navigationController presentViewController:nav
                                            animated:YES
                                          completion:NULL];
}

- (BOOL)hasHitNotificationLimit {
    
    NSInteger currentCount = (NSInteger )[SVPodcast MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"shouldNotify == YES AND isSubscribed == YES"] inContext:[PodsterManagedDocument defaultContext]];
    BOOL premium = [[SVSettings sharedInstance] premiumModeUnlocked];
    return !premium && currentCount >= [[SVSettings sharedInstance] maxFreeNotifications];
}

- (void)showNotificationsUpsell
{
    [FlurryAnalytics logEvent:@"HitLimitUpsell"];
    NSString *title = NSLocalizedString(@"MAX_NOTIFICATIONS_UPDGRADE_PROMPT_TITLE", @"Title for the prompt asking the user to updgrade to premium");
    NSString *body = NSLocalizedString(@"HIT_MAX_NOTIFICATIONS_PROMPT_BODY", @"Body text prompting the user to upgrade to upgrade when they hit the free notifications limit" );
    BlockAlertView *signupAlert =  [BlockAlertView alertWithTitle:title
                                                          message:body];
    [signupAlert addButtonWithTitle:NSLocalizedString(@"LEARN_MORE", @"Find out more about a given option") block:^{
        [FlurryAnalytics logEvent:@"LimitUpsellLearnMoreTapped"];
        UIViewController *controller = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController];
        [self presentModalViewController:controller animated:YES];                
    }];
    
    [signupAlert setCancelButtonWithTitle:NSLocalizedString(@"No, Thanks", @"No, Thanks") block:^{
        [FlurryAnalytics logEvent:@"LimitUpsellDeclined"];
    }];
    [signupAlert show];
}

- (void)updateNotificationSetting:(BOOL)shouldNotify {
    if (![[SVSettings sharedInstance] notificationsEnabled]) {
        return;
    }

    if (shouldNotify && [self hasHitNotificationLimit])  {
        [self showNotificationsUpsell];
        return;
    }

    // Check if it's not subscribed, if not, subscribe them, then try again
    if (shouldNotify && !localPodcast.isSubscribedValue) {
        DDLogInfo(@"Podcast was not subscribed to");
        // User wants notifications and is not subscribed, subscribe them
        [self subscribeToPodcastWithSuccessBlock:^(BOOL success) {
            DDLogInfo(@"Subscribing succeded with status: %@", success ? @"Success" : @"Failure");
            if (success) {
                [self updateNotificationSetting:shouldNotify];
            }
        }];
        return;
    }

    // Actually do the notification update
    [[SVPodcatcherClient sharedInstance] changeNotificationSetting:shouldNotify
                                                     forFeedWithId:localPodcast.podstoreId
                                                      onCompletion:^{
                                                          [FlurryAnalytics logEvent:@"ChangedNotificationSettingForFeed"
                                                                     withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:shouldNotify] forKey:@"ON"]];
                                                          LOG_GENERAL(2, @"Notifications setting changed successfully");
                                                          [localContext performBlock:^{
                                                              localPodcast.shouldNotifyValue = shouldNotify;
                                                          }];
                                                      }
            onError:^(NSError *error) {
                [FlurryAnalytics logError:@"ChangedNotificationSettingForFeed" message:[error localizedDescription] error:error ];
                DDLogError(@"Error when chanigng notification settings: %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{


                    BlockAlertView *alertView= [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle] message:@"There was a problem communicating with the Podster servers. Please try again later."];

                    [alertView setCancelButtonWithTitle:@"OK" block:^{

                    }];

                    [alertView show];
                });
            }];

}

- (IBAction)notifySwitchChanged:(id)sender {

}

- (void)showFeedNotificationSubscriptionError
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle] message:NSLocalizedString(@"NOTIFICAITONS_SUBSCRIBE_FAILED", @"Podster was unable to reach the server to set up notifications for this podcast. Please try again later from this podcast's settings area.")];
    [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK") block:^{}];
    [alert show];
}

- (void)askUserIfTheyWantNotifications
{
    // If notifications are enabled, figure out if we want to subscribe for this podcast
    LOG_GENERAL(2, @"Checking if notifications are enabled");
    if([[SVSettings sharedInstance] notificationsEnabled]){
        
        SVSettings *settings = [SVSettings sharedInstance];
        BOOL shouldAskAboutNotifications = [settings notificationsEnabled];
        
        if (shouldAskAboutNotifications) {
            void (^subscribeWithErrorAlertBlock)() = ^{
                if([self hasHitNotificationLimit]) {
                    [self showNotificationsUpsell];
                } else {
                    LOG_GENERAL(2, @"Creating notification subscription");
                    [[SVPodcatcherClient sharedInstance] changeNotificationSetting:YES
                                                                    forFeedWithId:localPodcast.podstoreId
                                                                      onCompletion:^{
                                                                          LOG_GENERAL(2, @"Succeed creating notification subscription");
                                                                          localPodcast.shouldNotifyValue = YES;
                                                                      }
                                                                           onError:^(NSError *error) {
                                                                               LOG_GENERAL(2, @"Failed creating notification subscription");
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   [self showFeedNotificationSubscriptionError];
                                                                                
                                                                               });
                                                                               
                                                                           }];
                }
            };            
            
            BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Notifications", @"Notifications")
                                                           message:NSLocalizedString(@"Would you like to be notified when new episodes become available?", @"Would you like to be notified when new episodes become available?")];
            [alert setCancelButtonWithTitle:@"No" block:^{

            }];
            [alert addButtonWithTitle:@"Yes"
                                block:^{
                                    subscribeWithErrorAlertBlock();
                                }];
            
            [alert show];
            
        }
    }
}

-(void)subscribeToPodcast
{
    [localContext performBlock:^void() {
        // Trigger the object itself to say it is subscribed
        [localPodcast subscribe];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureToolbar];            
        });
    }];

    // Tell the server
    [self subscribeToPodcastWithSuccessBlock:^(BOOL success) {
        if(success) {
            [self askUserIfTheyWantNotifications];
        }
    }];
}

- (void)subscribeToPodcastWithSuccessBlock:(void (^)(BOOL))complete
{
    
    dispatch_async(dispatch_get_main_queue(), ^void() {
        LOG_GENERAL(2, @"Creating a subscription for this podcast");
    });

    [FlurryAnalytics logEvent:@"SubscribedToFeed"];
        
    void (^succeeded)() = ^{
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(YES);                
            });
            
        }
        
    };
    
    [[SVPodcatcherClient sharedInstance] subscribeToFeedWithId:localPodcast.podstoreId
                                                  onCompletion:succeeded
                                                       onError:^(NSError *error) {
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(NO);
            });
        }
    }];
}

- (void)unsubscribeFromPodcast
{
    [FlurryAnalytics logEvent:@"UnsubscribedFromPodcast"];

    [localContext performBlock:^void() {
        [localPodcast unsubscribe];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureToolbar];            
        });        
    }];
    
    [[SVPodcatcherClient sharedInstance] unsubscribeFromFeedWithId:localPodcast.podstoreId
                                                           onCompletion:^{
                                                           } onError:^(NSError *error) {
                                                           }];
}

- (IBAction)subscribeTapped:(id)sender {
    LOG_GENERAL(2, @"Subscribe tapped");
    if(!localPodcast.isSubscribedValue) {
        [self subscribeToPodcast];
    } else {
        [self unsubscribeFromPodcast];             
    } 

}

- (void)configureToolbar
{
    NSMutableArray *barItems = [NSMutableArray array];
    BOOL subscribed = localPodcast.isSubscribedValue;
    if (subscribed) {

        UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star.png"]
                                                   landscapeImagePhone:nil
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(subscribeTapped:)];
        item.tintColor = [UIColor yellowColor];
        [barItems addObject:item];
        
    } else {
        [barItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"empty-star.png"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self
                                                            action:@selector(subscribeTapped:)]];
    }
    
    if ([TWTweetComposeViewController canSendTweet]) {
        [barItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
        [barItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                          target:self
                                                                          action:@selector(shareTapped:)]];
    }

    [barItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]];
    if(subscribed) {
        [barItems addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"]
                                    landscapeImagePhone:nil
                                                  style:UIBarButtonItemStylePlain
                                                 target:self action:@selector(optionsTapped:)]];
    }

    [self setToolbarItems:barItems animated:YES];
}
#pragma mark - View lifecycle
-(void)dealloc
{
    LOG_GENERAL(2, @"dealloc");
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
}
- (void)loadFeedImage
{
    if ([localPodcast isKindOfClass:[SVPodcast class]]) {
        SVPodcast *coredataPodcast = (SVPodcast *)localPodcast;
        if (coredataPodcast.listSizeImageData) {
            UIImage *img = [UIImage imageWithData:coredataPodcast.listSizeImageData];
            self.imageView.image = img;
        } else {
            [imageView setImageWithURL:[NSURL URLWithString:localPodcast.thumbLogoURL] placeholderImage:imageView.image];
        }
    } else {
        [imageView setImageWithURL:[NSURL URLWithString:localPodcast.thumbLogoURL] placeholderImage:imageView.image];
    }

}
-(void)viewDidDisappear:(BOOL)animated
{
    
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [FlurryAnalytics endTimedEvent:@"PodcastDetailsPageView"  withParameters:nil];
}

- (void)setupSubscribeButton
{
    [localContext performBlock:^{
        BOOL subscribed = localPodcast.isSubscribedValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(subscribed) {
                self.subscribeButton.image = [UIImage imageNamed:@"heart-highlighted.png"];
            }
            
            
            self.subscribeButton.enabled = YES;
        });
    }];
}

- (void)viewDidLoad
{
    LOG_GENERAL(2, @"%s", sel_getName(_cmd));
    [super viewDidLoad];
    
    //    GCDiscreetNotificationView *notificationView = [[GCDiscreetNotificationView alloc] initWithText:NSLocalizedString(@"Loading new episodes", @"Loading new episodes") showActivity:YES inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom inView:self.view];
    isInitialLoad = YES;
    
    self.navigationItem.title = NSLocalizedString(@"Details", @"Details");

    self.tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    self.titleLabel.text = self.podcast.title;
//    
//    UIActivityIndicatorView *imageSpinner = [[UIActivityIndicatorView alloc] initWithFrame:self.imageView.frame];
//    [imageSpinner setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
//    [self.imageView addSubview:imageSpinner];
//    [imageSpinner startAnimating];
//    [imageSpinner setHidesWhenStopped:YES];
        
    isLoading = YES;
    
    localContext = [PodsterManagedDocument defaultContext];
    __block BOOL blockHasSubscription = NO;
    
    [localContext performBlock:^{
        @try {
            
            NSNumber *feedId= self.podcast.podstoreId;
            NSAssert(feedId, @"Feed id should be present");
            LOG_GENERAL(2, @"Looking up podcast in data store with Id: %@", feedId);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.podstoreId, feedId];
            localPodcast = [SVPodcast MR_findFirstWithPredicate:predicate
                                                      inContext:localContext];
            DDLogVerbose(@"Lookup complete");
            
            if (!localPodcast) {
                LOG_GENERAL(2, @"Podcast with id %@ didn't exist, creating it", feedId);
                localPodcast = [SVPodcast MR_createInContext:localContext];                

                dispatch_async(dispatch_get_main_queue(), ^{                    
                    // We didn't have a local copy, so load from url
                    [self.imageView setImageWithURL:[NSURL URLWithString:[self.podcast thumbLogoURL]]];
             //       [imageSpinner stopAnimating];
                });
            } else {
                // We had a local copy, so check for local image
                if (localPodcast.gridSizeImageData != nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{                                                
                        UIImage *image = [UIImage imageWithData:localPodcast.gridSizeImageData];
                        self.imageView.image = image;
                      //  [imageSpinner stopAnimating];
                    });
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{                    
                        // We didn't have a local copy, so load from url
                        [self.imageView setImageWithURL:[NSURL URLWithString:[self.podcast thumbLogoURL]]];
                      //  [imageSpinner stopAnimating];
                    }); 
                }
                LOG_GENERAL(2, @"Retrived: %@ - %@", localPodcast.title, localPodcast.objectID);
            }
            [localPodcast populateWithPodcast:self.podcast];
            blockHasSubscription = localPodcast.isSubscribedValue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.descriptionLabel.text = localPodcast.summary;    
                isSubscribed = blockHasSubscription;
                self.subscribeButton.enabled = NO;
                
                [self setupSubscribeButton];
                
                __weak SVPodcastDetailsViewController *blockSelf = self;
                
                void (^loadCompleteHandler)() = ^{
                    if(blockSelf) {
                        if ([gracePeriodTimer isValid]) {
                            [gracePeriodTimer invalidate];
                        }

                        blockSelf->isLoading = NO;
                        LOG_GENERAL(2, @"Done loading entries");                    
                        [blockSelf loadFeedImage];
                    
                        [self reloadData];
                    }
                    
                };                
             
                gracePeriodTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 
                                                                    target:self selector:@selector(gracePeriodTimerFired:) 
                                                                  userInfo:nil
                                                                   repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:gracePeriodTimer forMode:NSDefaultRunLoopMode];
                
                [localContext performBlock:^{
                    if ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable) {
                    [localPodcast getNewEpisodes:^(BOOL success) {
                        if (!success) {
                            if (blockSelf) {

                                BlockAlertView *alert = [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle]
                                                                               message:NSLocalizedString(@"There was an error downloading this podcast. Please try again later", @"There was an error downloading this podcast. Please try again later")];
                                [alert setCancelButtonWithTitle:NSLocalizedString(@"OK",nil)
                                                          block:^{
                                                              
                                                          }];
                                [alert show];
                                //[localPodcast updateNextItemDateAndDownloadIfNecessary:YES];
                            }
                        }
                        else {
                            loadCompleteHandler();
                        }
                    }];
                    } else {
                        loadCompleteHandler();
                    }
                }];
                
                [self reloadData];

            });
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }        
    }];    
}
- (void)gracePeriodTimerFired:(NSTimer *)timer
{
 
    

}
-(void)reloadData
{
    if (![NSThread isMainThread]) {
        LOG_GENERAL(2, @"Bouncing back to main thread");
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    LOG_GENERAL(2, @"Reload Data begun");

    [localContext performBlock:^void() {
        @try {

            DDLogVerbose(@"Reload block started");
            items = [localPodcast.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SVPodcastEntryAttributes.datePublished ascending:!localPodcast.sortNewestFirstValue]]];
            if (localPodcast.hidePlayedEpisodesValue) {
                items = [items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = NO", SVPodcastEntryAttributes.played]];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self tableView] reloadData];
                DDLogVerbose(@"REload Data complete");
            });
        }
        @catch (NSException *exception) {
            DDLogError(@"Error occured while reloading data: %@", exception);
        }
        @finally {

        }
    }];
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setTableView:nil];
    [self setMetadataView:nil];
    [self setImageView:nil];
    [self setSubscribeButton:nil];

    [self setOptionsButton:nil];
    [self setOptionsButton:nil];

    [self setShareButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return interfaceOrientation == UIInterfaceOrientationPortrait;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self reloadData];
     [self configureToolbar];
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSAssert(localPodcast != nil, @"Local podcast should not be nil");
  //  [localPodcast updateNextItemDateAndDownloadIfNecessary:YES];

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
    [FlurryAnalytics logEvent:@"PodcastDetailsPageView" timed:YES];       
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVPodcastEntry *episode = [items objectAtIndex:(NSUInteger) indexPath.row];
    if (episode == [[SVPlaybackManager sharedInstance] currentEpisode]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
        NSParameterAssert(controller);
        
        DDLogInfo(@"Navigating to player");
        [[self navigationController] pushViewController:controller animated:YES];
    } else {
        
        [localContext performBlock:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (episode.downloadCompleteValue || ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] != AFNetworkReachabilityStatusNotReachable)) {
                    // If it's downloaded or we're online, play it
                    BOOL isVideo = NO;
                    isVideo |=  [episode.mediaURL rangeOfString:@"m4v" options:NSCaseInsensitiveSearch].location != NSNotFound;
                    isVideo |=  [episode.mediaURL rangeOfString:@"mov" options:NSCaseInsensitiveSearch].location != NSNotFound;
                    isVideo |=  [episode.mediaURL rangeOfString:@"mp4" options:NSCaseInsensitiveSearch].location != NSNotFound;
                    if (isVideo) {
                        NSURL *contentUrl = episode.downloadCompleteValue ? [NSURL fileURLWithPath: episode.localFilePath] :  [NSURL URLWithString:episode.mediaURL];
                        MPMoviePlayerViewController *player =
                        [[MPMoviePlayerViewController alloc] initWithContentURL: contentUrl];
                        [self presentMoviePlayerViewControllerAnimated:player];
                    }else {                    
                        DDLogInfo(@"Triggering playback");
                        [[SVPlaybackManager sharedInstance] playEpisode:episode ofPodcast:episode.podcast];
                        DDLogInfo(@"Playback triggered");
                        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                        UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
                        NSParameterAssert(controller);
                        
                        DDLogInfo(@"Navigating to player");
                        [[self navigationController] pushViewController:controller animated:YES];
                        
                    }
                } else {
                    BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Offline", @"offline")
                                                                   message:NSLocalizedString(@"This episode is not available offline", nil)];
                    [alert setCancelButtonWithTitle:NSLocalizedString(@"OK",nil)
                                              block:^{
                                                  
                                              }];
                    [alert show];
                }
            });
            
        }];
    }
    // Download episode
    //[[SVDownloadManager sharedInstance] downloadEntry:episode];
    
    
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    SVEpisodeDetailsViewController *details = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"episodeDetails"];    
    details.episode =[items objectAtIndex:(NSUInteger) indexPath.row];
    [[self navigationController] pushViewController:details
                                           animated:YES];
    
    
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    static UIColor *cellBackground;
    if (!cellBackground) {
        cellBackground = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"CarbonListBackground.png"]];
    }
    cell.backgroundColor = cellBackground;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    SVEpisodeListCell  *cell = (SVEpisodeListCell *)[tableView 
                                                     dequeueReusableCellWithIdentifier:@"episodeCell"];
    //cell.backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"CarbonListBackground.png"] resizableImageWithCapInsets:UIEdgeInsetsZero]];
    //cell.backgroundView.backgroundColor = ;
    SVPodcastEntry *episode= [items objectAtIndex:(NSUInteger) indexPath.row];
    
    [cell bind:episode];    
    
    return cell;
    
}

#pragma mark - datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return items.count;
}

- (IBAction)shareTapped:(id)sender {
    TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
    [tweet setInitialText:[NSString stringWithFormat:@"%@ (via @ItsPodster)", localPodcast.title]];
    [tweet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.podsterapp.com/feeds/%d", localPodcast.podstoreIdValue]]];
    
    // Show the controller
    [self presentModalViewController:tweet animated:YES];
    
    // Called when the tweet dialog has been closed
    tweet.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
        // Dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };
}


#pragma mark - podcast settings delegate
- (void)podcastSettingsViewControllerShouldClose:(PodcastSettingsViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:NULL];
    [localContext performBlock:^void() {
        localPodcast.sortNewestFirstValue = !controller.sortAscending;
        if (localPodcast.shouldNotifyValue != controller.shouldNotify) {
            [self updateNotificationSetting:controller.shouldNotify];
        }

        localPodcast.downloadsToKeepValue = controller.downloadsToKeep;
    }];
}

@end
