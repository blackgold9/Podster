//
//  SVPodcastDetailsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastDetailsViewController.h"
#import "MWFeedItem.h"
#import "MWFeedParser.h"
#import "MWFeedInfo.h"
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
#import "MTStatusBarOverlay.h"
#import "SVSubscriptionManager.h"
#import "_SVPodcastEntry.h"
#import "_SVPodcast.h"
@interface SVPodcastDetailsViewController ()


- (void)reloadData;
@end
@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    MWFeedInfo *feedInfo;
    MWFeedParser *feedParser;
    NSManagedObjectContext *localContext;
    BOOL shouldSave;
    SVPodcast *localPodcast;
    UIView *headerView;
    BOOL optionsOpen;
    BOOL isInitialLoad;
    BOOL isSubscribed;
    NSArray *items;
    NSManagedObjectContext *context;
    NSTimer *gracePeriodTimer;
}
@synthesize notifyOnUpdateLabel;
@synthesize notifyDescriptionLabel;
@synthesize hidePlayedItemsLabel;
@synthesize notifySwitch;
@synthesize sortSegmentedControl;
@synthesize hidePlayedSwitch;
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
    
    // Release any cached data, images, etc that aren't in use.
}

- (IBAction)infoTapped:(id)sender {
    SVPodcastModalView *modal = [[SVPodcastModalView alloc] initWithFrame:self.view.bounds ];
    modal.podcast = localPodcast;
    [self.view addSubview:modal];
    [modal showFromPoint:((UIView *)sender).center];
}

- (IBAction)hidePlayedSwitchedByUser:(id)sender {
    localPodcast.hidePlayedEpisodesValue = self.hidePlayedSwitch.on;
    [self reloadData];
}

- (IBAction)sortControlTapped:(id)sender {
    localPodcast.sortNewestFirstValue = self.sortSegmentedControl.selectedSegmentIndex == 0;
    
    [self reloadData];
}
- (BOOL)hasHitNotificationLimit {
    
    NSInteger currentCount = (NSInteger )[SVPodcast MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"shouldNotify == YES AND isSubscribed == YES"] inContext:[PodsterManagedDocument defaultContext]];
    return ![[SVSettings sharedInstance] premiumModeUnlocked] && currentCount >= [[SVSettings sharedInstance] maxFreeNotifications];
}

- (void)showNotificationsUpsell
{
    [FlurryAnalytics logEvent:@"HitLimitUpsell"];
    NSString *title = NSLocalizedString(@"MAX_NOTIFICATIONS_UPDGRADE_PROMPT_TITLE", @"Title for the prompt asking the user to updgrade to premium");
    NSString *body = NSLocalizedString(@"HIT_MAX_NOTIFICATIONS_PROMPT_BODY", @"Body text prompting the user to upgrade to upgrade when they hit the free notifications limit" );
    BlockAlertView *signupAlert =  [BlockAlertView alertWithTitle:title
                                                          message:body];
    [signupAlert addButtonWithTitle:NSLocalizedString(@"LEARN_MORE", @"Find out more about a given option") block:^{
        // Take to the signup page?
        [FlurryAnalytics logEvent:@"LimitUpsellLearnMoreTapped"];
        UIViewController *controller = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController];
        [self.navigationController pushViewController:controller animated:YES];
        
        
    }];
    
    [signupAlert setCancelButtonWithTitle:NSLocalizedString(@"No, Thanks", @"No, Thanks") block:^{
        [FlurryAnalytics logEvent:@"LimitUpsellDeclined"];
    }];
    [signupAlert show];
    [self.notifySwitch setOn:NO animated:YES];
    
}
-(void)doNotificationChange
{
    if (self.notifySwitch.on && [self hasHitNotificationLimit])  {
        [self showNotificationsUpsell];
    } else {
        
        [[SVPodcatcherClient sharedInstance] changeNotificationSetting:self.notifySwitch.on
                                                        forFeedWithURL:localPodcast.feedURL
                                                          onCompletion:^{
                                                              [FlurryAnalytics logEvent:@"ChangedNotificationSettingForFeed"
                                                                         withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:self.notifySwitch.on] forKey:@"ON"]];
                                                              LOG_GENERAL(2, @"Notifications setting changed successfully");
                                                              localPodcast.shouldNotifyValue = self.notifySwitch.on;
                                                              
                                                          }
                                                               onError:^(NSError *error) {
                                                                   
                                                                   if ([error code] == 402) {
                                                                       // recieved a 'payment required' status code
                                                                       [self showNotificationsUpsell];
                                                                   } else {
                                                                       [FlurryAnalytics logError:@"ChangedNotificationSettingForFeed" message:[error localizedDescription] error:error ];
                                                                       LOG_GENERAL(1, @"Registration failed with error: %@", error);
                                                                       BlockAlertView *alertView= [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle] message:@"There was a problem communicating with the Podster servers. Please try again later."];
                                                                       
                                                                       [alertView setCancelButtonWithTitle:@"OK" block:^{
                                                                           
                                                                       }];
                                                                       [self.notifySwitch setOn:!self.notifySwitch.on animated:YES];
                                                                       [alertView show];
                                                                   }
                                                               }];
    }
}

- (IBAction)notifySwitchChanged:(id)sender {
    if([[SVSettings sharedInstance] notificationsEnabled]){
        
        [self subscribeToPodcastWithSuccessBlock:^(BOOL success) {
            if (success) {
                
            }
        }];        
    } 
    else 
    {
        // Notifications not enabled
        BlockAlertView *alertView = [BlockAlertView alertWithTitle:NSLocalizedString(@"NOTIFICATIONS_ARE_DISABLED", @"Notifications are disabled")
                                                           message:NSLocalizedString(@"NOTIFICATIONS_DISABLED_BODY", @"Please enable notifications in settings if you would like to recieve updates when new episodes are posted.")];
        [alertView setCancelButtonWithTitle:NSLocalizedString(@"OK",nil) block:^{
            
        }];
        [self.notifySwitch setOn:NO animated:YES];
        [alertView show];
    }
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
                                                                    forFeedWithURL:localPodcast.feedURL
                                                                      onCompletion:^{
                                                                          LOG_GENERAL(2, @"Succeed creating notification subscription");
                                                                          self.subscribeButton.enabled = YES;
                                                                          localPodcast.shouldNotifyValue = YES;
                                                                          
                                                                          [self.notifySwitch setOn:YES animated:YES];
                                                                      }
                                                                           onError:^(NSError *error) {
                                                                               LOG_GENERAL(2, @"Failed creating notification subscription");
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   [self showFeedNotificationSubscriptionError];
                                                                                   self.subscribeButton.enabled = YES;
                                                                               });
                                                                               
                                                                           }];
                }
            };
            
            
            BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Notifications", @"Notifications")
                                                           message:NSLocalizedString(@"Would you like to be notified when new episodes become available?", @"Would you like to be notified when new episodes become available?")];
            [alert setCancelButtonWithTitle:@"No" block:^{
                self.subscribeButton.enabled = YES;
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
    
    [self subscribeToPodcastWithSuccessBlock:^(BOOL success) {
        if(success) {
            [self askUserIfTheyWantNotifications];
        }
    }];
    [localPodcast downloadOfflineImageData];
}

- (void)subscribeToPodcastWithSuccessBlock:(void (^)(BOOL))complete
{
    isSubscribed = YES;
    dispatch_async(dispatch_get_main_queue(), ^void() {
        LOG_GENERAL(2, @"Creating a subscription for this podcast");
        // User is making this a favorite
        self.subscribeButton.image = [UIImage imageNamed:@"heart-highlighted.png"];
    });
    [FlurryAnalytics logEvent:@"SubscribedToFeed"];
    
    [localContext performBlock:^void() {
        localPodcast.isSubscribedValue = YES;
        
        LOG_GENERAL(2, @"Communication pending with server. Setting Needs reconcile to YES");
        // Start out needing reconciling
        localPodcast.unseenEpsiodeCountValue = 0;
        
    }];
    
    void (^succeeded)() = ^{
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(YES);                
            });
            
        }
        
    };
    
    [[SVPodcatcherClient sharedInstance] subscribeToFeedWithURL:localPodcast.feedURL shouldNotify:NO onCompletion:succeeded onError:^(NSError *error) {
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
    self.subscribeButton.enabled = YES;
    self.subscribeButton.image = [UIImage imageNamed:@"heart.png"];
    isSubscribed = NO;
    [self.notifySwitch setOn:NO animated:YES];
    [localContext performBlock:^void() {
        localPodcast.isSubscribedValue = NO;
        localPodcast.shouldNotifyValue = NO;
        
    }];
    
    [[SVPodcatcherClient sharedInstance] notifyOfUnsubscriptionFromFeed:localPodcast.feedURL
                                                           onCompletion:^{
                                                           } onError:^(NSError *error) {
                                                           }];
}

- (IBAction)subscribeTapped:(id)sender {
    LOG_GENERAL(2, @"Subscribe tapped");
    if(!isSubscribed) {
        [self subscribeToPodcast];
    } else {
        [self unsubscribeFromPodcast];             
    } 
}

- (IBAction)optionsButtonTapped:(id)sender {
    [self toggleOptionsPanel:!optionsOpen
                    animated:YES];
}

- (void)toggleOptionsPanel:(BOOL)open animated:(BOOL)animated
{
    optionsOpen = open;
    if (!open) {
        [UIView animateWithDuration:animated ? 0.33 : 0.0
                         animations:^{
                             self.metadataView.frame = CGRectMake(0, 0, 320, 88);
                             self.optionsButton.transform = CGAffineTransformIdentity;
                             self.tableView.frame = CGRectMake(0, 88, 320, self.view.frame.size.height - 88);
                         }];
    } else {
        [UIView animateWithDuration:animated ? 0.33 : 0.0
                         animations:^{
                             
                             self.metadataView.frame = CGRectMake(0, 0, 320, 220);
                             
                             self.tableView.frame = CGRectMake(0, 220, 320, self.view.frame.size.height - 220);
                         }];
    }
    
    [UIView animateWithDuration:0.15 animations:^{
        self.optionsButton.transform = open ? CGAffineTransformMakeRotation((CGFloat) M_PI) : CGAffineTransformIdentity;
    }];
    
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
    [imageView setImageWithURL:[NSURL URLWithString:localPodcast.thumbLogoURL] placeholderImage:imageView.image];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [localContext performBlock:^{
        localPodcast.unseenEpsiodeCountValue = 0;
    }];
    
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [FlurryAnalytics endTimedEvent:@"PodcastDetailsPageView"  withParameters:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    self.notifyDescriptionLabel.text = NSLocalizedString(@"Poster will send you an alert when new episodes of this podcast are available", @"Poster will send you an alert when new episodes of this podcast are available");
    self.notifyOnUpdateLabel.text =  NSLocalizedString(@"Notify Me On Update", @"Notify Me On Update");
    self.hidePlayedItemsLabel.text = NSLocalizedString(@"Hide Played Items", @"Hide Played Items");
    [self.sortSegmentedControl setTitle:NSLocalizedString(@"Newest First", @"Newest First") forSegmentAtIndex:0];
    [self.sortSegmentedControl setTitle:NSLocalizedString(@"Oldest First", @"Oldest First") forSegmentAtIndex:1];
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    self.titleLabel.text = self.podcast.title;
    
    [self.imageView setImageWithURL:[NSURL URLWithString:[self.podcast thumbLogoURL]]];
    isLoading = YES;
    
    localContext = [PodsterManagedDocument defaultContext];
    __block BOOL blockHasSubscription = NO;
    
    [localContext performBlock:^{
        @try {
            
            NSNumber *feedId= self.podcast.podstoreId;
            NSAssert(feedId, @"Feed id should be present");
            LOG_GENERAL(2, @"Lookuing up podcast in data store with Id: %@", feedId);
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.podstoreId, feedId];
            localPodcast = [SVPodcast MR_findFirstWithPredicate:predicate
                                                      inContext:localContext];
            
            
            if (!localPodcast) {
                LOG_GENERAL(2, @"Podcast with id %@ didn't exist, creating it", feedId);
                localPodcast = [SVPodcast MR_createInContext:localContext];
                [localContext performBlock:^{
                    [localContext save:nil];
                }];
            } else {
                LOG_GENERAL(2, @"Retrived: %@ - %@", localPodcast.title, localPodcast.objectID);
            }
            
            localPodcast.title = self.podcast.title;
            localPodcast.summary = self.podcast.summary;
            localPodcast.logoURL = self.podcast.logoURL;
            localPodcast.feedURL = self.podcast.feedURL;
            localPodcast.thumbLogoURL = [self.podcast thumbLogoURL];
            localPodcast.smallLogoURL = [self.podcast smallLogoURL];
            localPodcast.tinyLogoURL = [self.podcast tinyLogoURL];
            localPodcast.podstoreId = [self.podcast podstoreId];
            localPodcast.unseenEpsiodeCountValue = 0;
            blockHasSubscription = localPodcast.isSubscribedValue;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.descriptionLabel.text = localPodcast.summary;    
                isSubscribed = blockHasSubscription;
                self.notifySwitch.on = localPodcast.shouldNotifyValue;
                self.subscribeButton.enabled = NO;
                
                [self setupSubscribeButton];
                
                __weak SVPodcastDetailsViewController *blockSelf = self;
                
                void (^loadCompleteHandler)() = ^{
                    if(blockSelf) {
                        if ([gracePeriodTimer isValid]) {
                            [gracePeriodTimer invalidate];
                        }
                        [[MTStatusBarOverlay sharedInstance] hide];
                        blockSelf->isLoading = NO;
                        LOG_GENERAL(2, @"Done loading entries");                    
                        [blockSelf loadFeedImage];
                        [localContext performBlock:^{
                            [localContext save:nil];
                        }];
                        [self reloadData];
                    }
                    
                };                
             
                gracePeriodTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 
                                                                    target:self selector:@selector(gracePeriodTimerFired:) 
                                                                  userInfo:nil
                                                                   repeats:NO];
                [[NSRunLoop mainRunLoop] addTimer:gracePeriodTimer forMode:NSDefaultRunLoopMode];
                
                [localContext performBlock:^{
                    [localPodcast getNewEpisodes:^(BOOL success) {
                        if (!success) {
                            if (blockSelf) {
                                [[MTStatusBarOverlay sharedInstance] hide]; 
                                BlockAlertView *alert = [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle]
                                                                               message:NSLocalizedString(@"There was an error downloading this podcast. Please try again later", @"There was an error downloading this podcast. Please try again later")];
                                [alert setCancelButtonWithTitle:NSLocalizedString(@"OK",nil)
                                                          block:^{
                                                              
                                                          }];
                                [alert show];
                            }
                        }
                        else {
                            loadCompleteHandler();
                        }
                    }];
                }];
                
                [self reloadData];
                [self toggleOptionsPanel:NO animated:NO]; 
            });
        }
        @catch (NSException *exception) {
            NSLog(@"%@", exception);
        }        
    }];    
}
- (void)gracePeriodTimerFired:(NSTimer *)timer
{
    [[MTStatusBarOverlay sharedInstance] postMessage:NSLocalizedString(@"Loading new episodes", @"Loading new episodes") ];
    

}
-(void)reloadData
{
    if (![NSThread isMainThread]) {
        LOG_GENERAL(2, @"Bouncing back to main thread");
        [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    LOG_GENERAL(2, @"REload Data begun");
    self.hidePlayedSwitch.on = localPodcast.hidePlayedEpisodesValue;
    self.sortSegmentedControl.selectedSegmentIndex = localPodcast.sortNewestFirstValue ? 0 : 1;
    
    [localContext performBlockAndWait:^void() {
        items = [localPodcast.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SVPodcastEntryAttributes.datePublished ascending:!localPodcast.sortNewestFirstValue]]];
        if (localPodcast.hidePlayedEpisodesValue) {
            items = [items filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K = NO", SVPodcastEntryAttributes.played]];
        }
    }];
    
    
    [self.tableView reloadData];
    LOG_GENERAL(2, @"REload Data complete");
}
- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setTableView:nil];
    [self setMetadataView:nil];
    [self setImageView:nil];
    [self setSubscribeButton:nil];
    [self setHidePlayedSwitch:nil];
    [self setSortSegmentedControl:nil];
    [self setNotifySwitch:nil];
    [self setOptionsButton:nil];
    [self setOptionsButton:nil];
    [self setNotifyOnUpdateLabel:nil];
    [self setNotifyDescriptionLabel:nil];
    [self setHidePlayedItemsLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
    
}


-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    NSAssert(localPodcast != nil, @"Local podcast should not be nil");
    [localContext performBlock:^{
        
        localPodcast.unseenEpsiodeCountValue = 0;
        [localPodcast updateNextItemDateAndDownloadIfNeccesary:YES];
        
    }];
    [[PodsterManagedDocument sharedInstance] save:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [FlurryAnalytics logEvent:@"PodcastDetailsPageView" timed:YES];       
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    [localContext performBlock:^{
        SVPodcastEntry *episode = [items objectAtIndex:(NSUInteger) indexPath.row];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            BOOL isVideo = NO;
            isVideo |=  [episode.mediaURL rangeOfString:@"m4v" options:NSCaseInsensitiveSearch].location != NSNotFound;
            isVideo |=  [episode.mediaURL rangeOfString:@"mov" options:NSCaseInsensitiveSearch].location != NSNotFound;
            isVideo |=  [episode.mediaURL rangeOfString:@"mp4" options:NSCaseInsensitiveSearch].location != NSNotFound;
            if (isVideo) {
                MPMoviePlayerViewController *player =
                [[MPMoviePlayerViewController alloc] initWithContentURL: [NSURL URLWithString:[episode mediaURL]]];
                [self presentMoviePlayerViewControllerAnimated:player
                 ];
            }else {
                
                LOG_GENERAL(3,@"Triggering playback");
                [[SVPlaybackManager sharedInstance] playEpisode:episode ofPodcast:episode.podcast];
                LOG_GENERAL(3,@"Playback triggered");
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
                NSParameterAssert(controller);
                
                LOG_GENERAL(3, @"Navigating to player");
                [[self navigationController] pushViewController:controller animated:YES];
                
            }
        });
        
    }];
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
@end
