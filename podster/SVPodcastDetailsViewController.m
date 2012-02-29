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

#import "SVEpisodeListCell.h"
#import "GTMNSString+HTML.h"
#import "SVEpisodeDetails.h"
#import "SVPlaybackManager.h"
#import "SVPlaybackController.h"
#import "SVSubscription.h"
#import "SVPodcastModalView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "SVPodcastSettingsView.h"
#import "BlockAlertView.h"
@interface SVPodcastDetailsViewController ()

- (void)saveLocalContextIncludingParent:(BOOL)includeParent;

- (void)reloadData;
@end
@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    MWFeedInfo *feedInfo;
    MWFeedParser *feedParser;
    NSManagedObjectContext *localContext;
    NSFetchedResultsController *fetcher;
    BOOL shouldSave;
    SVPodcast *localPodcast;
    UIView *headerView;
    BOOL optionsOpen;
    BOOL isInitialLoad;
    BOOL isSubscribed;
    
    NSManagedObjectContext *context;
}
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

    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)setPodcast:(id<ActsAsPodcast>)podcast
{
    NSParameterAssert(podcast);
    NSAssert(podcast.feedURL, @"The podcast did not have a feed url");
    _podcast = podcast;
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

- (IBAction)notifySwitchChanged:(id)sender {
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"notificationsEnabled"]){  
        if (localPodcast.subscription == nil) {
            BlockAlertView *alertView= [BlockAlertView alertWithTitle:@"Not a Favorite" message:@"You cannot recieve notifications about a podcast unless it is marked as a Favorite"];
            [alertView setCancelButtonWithTitle:@"OK" block:^{
                
            }];
            [self.notifySwitch setOn:NO animated:YES];
            [alertView show];
        } else {
            if (self.notifySwitch.on) {
                // Notify 
                NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];  
                
                [[SVPodcatcherClient sharedInstance] notifyOfSubscriptionToFeed:localPodcast.feedURL withDeviceId:deviceId onCompletion:^{
                    [FlurryAnalytics logEvent:@"SubscribedForNotifications"];
                    LOG_GENERAL(2, @"Registered for notifications on feed");
                    localPodcast.shouldNotifyValue = YES;
                    [localContext save];

                   
                } onError:^(NSError *error) {
                    [FlurryAnalytics logError:@"SubscribeFailed" message:[error localizedDescription] error:error ];
                    LOG_GENERAL(1, @"Registration failed with error: %@", error);
                    BlockAlertView *alertView= [BlockAlertView alertWithTitle:@"Network Error" message:@"There was a problem communicating with the Podster servers. Please try again alter."];
                    
                                      [alertView setCancelButtonWithTitle:@"OK" block:^{
                        
                    }];
                    [self.notifySwitch setOn:NO animated:YES];
                    [alertView show];
                    
                }];
                
            } else {
                // Unsuscribe on the server
                NSString *deviceId = [[NSUserDefaults standardUserDefaults] objectForKey:@"deviceId"];  
                [[SVPodcatcherClient sharedInstance] notifyOfUnsubscriptionFromFeed:localPodcast.feedURL withDeviceId:deviceId onCompletion:^{
                    [FlurryAnalytics logEvent:@"UnsubscribedForNotifications"];
                    
                    localPodcast.shouldNotifyValue = NO;
                    [localContext save];

                } onError:^(NSError *error) {
                    [FlurryAnalytics logError:@"UnsubscribeFailed" message:[error localizedDescription] error:error ];
                    LOG_GENERAL(1, @"unsubscribe failed with error: %@", error);
                    BlockAlertView *alertView= [BlockAlertView alertWithTitle:@"Network Error" message:@"There was a problem communicating with the Podster servers. Please try again alter."];
                    [alertView setCancelButtonWithTitle:@"OK" block:^{
                        
                    }];
                    [self.notifySwitch setOn:YES animated:YES];
                    [alertView show];                    
                }];
            }                    
        }
    } else {
        // Notifications not enabled
        BlockAlertView *alertView = [BlockAlertView alertWithTitle:@"Notifications are disabled" 
                                                           message:@"Please enable notifications in settings if you would like to recieve updates when new episodes are posted."];
        [alertView addButtonWithTitle:@"Settings" block:^{
            
        }];
        [alertView setCancelButtonWithTitle:@"Not Now" block:^{
            
        }];
        [self.notifySwitch setOn:NO animated:YES];
        [alertView show];
        
    }
}

- (void)showFeedNotificationSubscriptionError
{
    BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Error" message:@"Podster was unable to reach the server to set up notifications for this podcast. Please try again later from this podcast's settings area."];
    [alert setCancelButtonWithTitle:@"OK" block:^{}];
    [alert show];
}

- (void)subscribeToPodcast
{
    LOG_GENERAL(2, @"Creating a subscription for this podcast");
    // User is making this a favorite
    dispatch_async(dispatch_get_main_queue(), ^{
        self.subscribeButton.image = [UIImage imageNamed:@"heart-highlighted.png"];
    });
    
    [localContext performBlock:^{
        SVSubscription *subscription = [SVSubscription createInContext:localContext];
        localPodcast.subscription = subscription;
        localPodcast.unseenEpsiodeCountValue = 0;
        isSubscribed = YES;
        [localContext save];
    }];
    
    
    // If notifications are enabled, figure out if we want to subscribe for this podcast
    if([[SVSettings sharedInstance] notificationsEnabled]){
        NSString *deviceId = [[SVSettings sharedInstance] deviceId];
        SVSettings *settings = [SVSettings sharedInstance];
        BOOL shouldAskAboutNotifications = ![settings shouldAlwaysSubscribeToNotifications] && ![settings neverAutoSubscribeToNotifications];
        
        if (shouldAskAboutNotifications) {
            void (^subscribeWithErrorAlertBlock)() = ^{
                LOG_GENERAL(2, @"Creating notification subscription");
                [[SVPodcatcherClient sharedInstance] notifyOfSubscriptionToFeed:localPodcast.feedURL
                                                                   withDeviceId:deviceId onCompletion:^{
                                                                       LOG_GENERAL(2, @"Succeed creating notification subscription");
                                                                       self.subscribeButton.enabled = YES;
                                                                       localPodcast.shouldNotifyValue = YES;
                                                                       [self saveLocalContextIncludingParent:YES];
                                                                       [self.notifySwitch setOn:YES animated:YES];
                                                                   }
                                                                        onError:^(NSError *error) {
                                                                             LOG_GENERAL(2, @"Failed creating notification subscription");
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                [self showFeedNotificationSubscriptionError];
                                                                                self.subscribeButton.enabled = YES;
                                                                            });
                                                                            
                                                                        }];
            };
            
            BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Notifications"
                                                           message:@"Would you like to be notified when new episodes become available?"];
            [alert setCancelButtonWithTitle:@"No" block:^{
                self.subscribeButton.enabled = YES;
            }];
            [alert addButtonWithTitle:@"Yes"
                                block:^{
                                    subscribeWithErrorAlertBlock();
                                }];
            
            [alert show];
            
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            LOG_GENERAL(2, @"Subscribed- notifications disabled");
            self.subscribeButton.enabled = YES;
        });
    }

}

- (void)unsubscribeFromPodcast
{
    // USer is unsuscribing
    BOOL notificationsEnabled = [[SVSettings sharedInstance] notificationsEnabled];
    BOOL subscribedForNotifications = NO;
    
    subscribedForNotifications = localPodcast.shouldNotifyValue;                
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.subscribeButton.enabled = YES;
        self.subscribeButton.image = [UIImage imageNamed:@"heart.png"];
        [self.notifySwitch setOn:NO animated:YES];
    });

    SVSubscription *subscription = localPodcast.subscription;
    [subscription deleteInContext:localContext];
    localPodcast.shouldNotifyValue = NO;  
    [self saveLocalContextIncludingParent:YES];

    
    if (notificationsEnabled && subscribedForNotifications) {
        LOG_GENERAL(2, @"Notifications Enabled and user was signed up for them");

        [[SVPodcatcherClient sharedInstance]
         notifyOfUnsubscriptionFromFeed:localPodcast.feedURL
         withDeviceId:[[SVSettings sharedInstance] deviceId]
         onCompletion:^{
             LOG_GENERAL(2, @"Successfully unsubscribed from podcast notifications");
                           
             
         } onError:^(NSError *error) {
             dispatch_async(dispatch_get_main_queue(), ^{
                 LOG_GENERAL(2, @"We failed attempting to unsubscribe from notifications. Mark that syncing is needed");
                 [[SVSettings sharedInstance] setNotificationsNeedSyncing:YES];                 
             });
         }];
    }         
}

- (IBAction)subscribeTapped:(id)sender {
    LOG_GENERAL(2, @"Subscribe tapped");
    self.subscribeButton.enabled = NO;
    if(!isSubscribed) {
        [self subscribeToPodcast];
    } else {
        [self unsubscribeFromPodcast];             
    } 
}

- (void)saveLocalContextIncludingParent:(BOOL)includeParent
{
    [localContext save];
   
}

-(id<ActsAsPodcast>)podcast
{
    return _podcast;
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

-(void)updateTableHeader
{
//    if (fetcher.fetchedObjects.count < 4) {
//        if ([headerView superview]) {
//            // header is showing and it shouldnt, remove it
//            self.tableView.tableHeaderView = nil;
//            self.tableView.contentOffset = CGPointMake(0, -headerView.frame.size.height);
//        }
//        
//    } else {
//        if (isInitialLoad) {
//            // Only the first time do you need to do set the offset. 
//            self.tableView.contentOffset = CGPointMake(0, headerView.frame.size.height);
//            isInitialLoad = NO;
//        }
//        
//        // Should show yeader
//        if(![headerView superview]) {
//            // And it needs to be added.
//            self.tableView.tableHeaderView = headerView; 
//            self.tableView.contentOffset = CGPointMake(0, headerView.frame.size.height);
//            
//        }
//        
//    }
//    
   

}

//- (SVPodcastEntry *)saveAndReturnItemAtIndexPath:(NSIndexPath*)indexPath
//{
//    // NEed to save now
//    LOG_GENERAL(3, @"Starting save operation");
//    __block SVPodcastEntry *entry = nil;
//    [localContext performBlockAndWait:^{
//        entry = [fetcher objectAtIndexPath:indexPath];
//        [localContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:entry] error:nil];
//        LOG_GENERAL(2, @"Saving local context");
//        [localContext save];
//        LOG_GENERAL(2, @"local context saved");
//    }];
//    
//    NSError *error;
//    [fetcher performFetch:&error];
//    NSAssert(error == nil, @"there should be no error");
//    SVPodcastEntry *fetcherEpisode = [fetcher objectAtIndexPath:indexPath];
//    [localContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:fetcherEpisode] error:nil];
//    LOG_GENERAL(3, @"Save complete");
//    return fetcherEpisode;
//}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
   }
- (void)loadFeedImage
{
    [imageView setImageWithURL:[NSURL URLWithString:localPodcast.thumbLogoURL] placeholderImage:imageView.image shouldFade:YES];
}
-(void)viewDidDisappear:(BOOL)animated
{
    [localContext performBlock:^{
        localPodcast.unseenEpsiodeCountValue = 0;        
        [localContext save];
    }];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [FlurryAnalytics endTimedEvent:@"PodcastDetailsPageView"  withParameters:nil];
}

- (void)setupSubscribeButton
{
    [localContext performBlock:^{
        BOOL subscribed = localPodcast.subscription != nil;
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
    [super viewDidLoad];
            isInitialLoad = YES;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
//    self.metadataView.layer.shadowPath = CGPathCreateWithRect(self.metadataView.frame, NULL);
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    self.titleLabel.text = self.podcast.title;
    
    [self.imageView setImageWithURL:[NSURL URLWithString:[self.podcast thumbLogoURL]]];
    isLoading = YES;

    localContext = [NSManagedObjectContext contextThatNotifiesDefaultContextOnMainThread];
    __block BOOL blockHasSubscription = NO;
    [localContext performBlockAndWait:^{
                    LOG_GENERAL(2, @"Lookuing up podcast in data store");
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.feedURL, self.podcast.feedURL];
        localPodcast = [SVPodcast findFirstWithPredicate:predicate
                                           inContext:localContext];
        
        LOG_GENERAL(2, @"Retrived: %@", localPodcast);
        if (!localPodcast) {
            LOG_GENERAL(2, @"Podcast didn't exist, creating it");
            localPodcast =[SVPodcast createInContext:localContext];
        }
        
        localPodcast.title = self.podcast.title;
        localPodcast.summary = self.podcast.summary;
        localPodcast.logoURL = self.podcast.logoURL;
        localPodcast.feedURL = self.podcast.feedURL;
        localPodcast.thumbLogoURL = [self.podcast thumbLogoURL];
        localPodcast.smallLogoURL = [self.podcast smallLogoURL];
        localPodcast.tinyLogoURL = [self.podcast tinyLogoURL];
        localPodcast.unseenEpsiodeCountValue = 0;
        blockHasSubscription = localPodcast.subscription != nil;

        [localContext save];

    }];
    self.descriptionLabel.text = localPodcast.summary;    
    isSubscribed = blockHasSubscription;
    self.notifySwitch.on = localPodcast.shouldNotifyValue;
    self.subscribeButton.enabled = NO;
  
    [self setupSubscribeButton];
        
    __weak SVPodcastDetailsViewController *blockSelf = self;

    void (^loadCompleteHandler)() = ^{
        blockSelf->isLoading = NO;
        [self loadFeedImage];
        LOG_GENERAL(2, @"Saving local context");
        localPodcast.unseenEpsiodeCountValue = 0;
        [localContext performBlock:^{
            [localContext save];
        }];
        LOG_GENERAL(2, @"Done loading entries");
    };
    
    [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcastWithFeedURL:localPodcast.feedURL
                                                               withLowerPriority:NO     
                                                                     inContext:localContext
                                                                       onCompletion:loadCompleteHandler
                                                                            onError:^(NSError *error) {
              //  [UIAlertView showWithError:error];
            }];

   
    
    [self reloadData];
    [self toggleOptionsPanel:NO animated:NO];
}

-(void)reloadData
{
    self.hidePlayedSwitch.on = localPodcast.hidePlayedEpisodesValue;
    self.sortSegmentedControl.selectedSegmentIndex = localPodcast.sortNewestFirstValue ? 0 : 1;
    NSMutableArray *predicates = [NSMutableArray array];
    [predicates addObject:[NSPredicate predicateWithFormat:@"podcast.feedURL == %@", localPodcast.feedURL]];
    if (localPodcast.hidePlayedEpisodesValue){
        [predicates addObject:[NSPredicate predicateWithFormat:@"%K == NO", SVPodcastEntryAttributes.played]];
    }
    
    LOG_GENERAL(2, @"Created Fetcher For Podcast Details");
    fetcher = [SVPodcastEntry fetchAllSortedBy:SVPodcastEntryAttributes.datePublished
                                     ascending:!localPodcast.sortNewestFirstValue 
                                 withPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:predicates] 
                                       groupBy:nil 
                                      delegate:self
                                     inContext:[NSManagedObjectContext defaultContext]];
    [self.tableView reloadData];
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
    [self.tableView reloadData];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [FlurryAnalytics logEvent:@"PodcastDetailsPageView" timed:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
       
    [localContext performBlock:^{
        if ([localContext hasChanges]) {
            [localContext save];
        }
         SVPodcastEntry *fetcherEpisode;
        fetcherEpisode = [fetcher objectAtIndexPath:indexPath];
        SVPodcastEntry *episode = (SVPodcastEntry *)[[NSManagedObjectContext defaultContext] existingObjectWithID:fetcherEpisode.objectID error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            BOOL isVideo = NO;
            isVideo |=  [episode.mediaURL rangeOfString:@"m4v" options:NSCaseInsensitiveSearch].location != NSNotFound;
            isVideo |=  [episode.mediaURL rangeOfString:@"mov" options:NSCaseInsensitiveSearch].location != NSNotFound;
            isVideo |=  [episode.mediaURL rangeOfString:@"mp4" options:NSCaseInsensitiveSearch].location != NSNotFound;
            if (isVideo) {
                //        if ([[SVPodcatcherClient sharedInstance] isOnWifi]) {
                MPMoviePlayerViewController *player =
                [[MPMoviePlayerViewController alloc] initWithContentURL: [NSURL URLWithString:[episode mediaURL]]];
                [self presentMoviePlayerViewControllerAnimated:player
                 ];
                
                //        }
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
    details.episode =[fetcher objectAtIndexPath:indexPath];
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
        SVPodcastEntry *episode= [fetcher objectAtIndexPath:indexPath];
    
    [cell bind:episode];    
    
    return cell;
    
}
#pragma mark - fetcher delegate
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject 
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath 
{

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        
        default:
            NSLog(@"Other udpate");
            break;
    }

}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];

}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    [self updateTableHeader];

}

#pragma mark - datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[fetcher sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}
@end
