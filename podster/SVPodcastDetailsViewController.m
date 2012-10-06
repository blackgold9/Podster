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
#import "SVPlaybackManager.h"
#import "MessageGenerator.h"
#import "SVEpisodeListCell.h"
#import "SVEpisodeDetails.h"
#import <MediaPlayer/MediaPlayer.h>
#import "BlockAlertView.h"
#import <Twitter/Twitter.h>
#import "PodcastImage.h"
#import "PodcastSettingsViewController.h"
#import "SVHtmlViewController.h"
#import "PodcastUpdateOperation.h"
#import "SVSubscriptionManager.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
@interface SVPodcastDetailsViewController () <PodcastSettingsViewControllerDelegate>
@property (nonatomic, strong) SVPodcast *podcast;

@end
@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    BOOL optionsOpen;
    BOOL isInitialLoad;
    BOOL isSubscribed;
    NSTimer *gracePeriodTimer;
    NSOperationQueue *updateOperationQueue;
    NSFetchedResultsController *fetcher;
    BOOL podcastLoaded;
    id observer;
}
@synthesize shareButton;
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize tableView = _tableView;
@synthesize metadataView;
@synthesize imageView;
@synthesize subscribeButton;

@synthesize optionsButton;
@synthesize context = _context;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization

        [self sharedInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization

        [self sharedInit];
    }

    return self;
}
- (void)sharedInit
{
    updateOperationQueue = [[NSOperationQueue alloc] init];
    podcastLoaded = NO;
    self.restorationIdentifier = @"podcastDetailsController";
    self.restorationClass = [self class];
}
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    [coder encodeObject:self.podcastId forKey:@"podcastId"];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    self.podcastId = [coder decodeObjectForKey:@"podcastId"];
}
+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder
{
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.podcastId = [coder decodeObjectForKey:@"podcastId"];
    [controller sharedInit];
    return controller;
}

#pragma mark - core data context
- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [NSManagedObjectContext MR_defaultContext];
    }

    return _context;
}

- (void)optionsTapped:(id)sender {
    UIStoryboard *board = [UIStoryboard storyboardWithName:@"PodcastStoryboard" bundle:nil];

    PodcastSettingsViewController *controller = [board instantiateViewControllerWithIdentifier:@"PodcastSettings"];
    [self.context performBlockAndWait:^{
        controller.shouldNotify = self.podcast.shouldNotifyValue;
        controller.sortAscending = !self.podcast.sortNewestFirstValue;
        controller.downloadsToKeep = (NSUInteger) self.podcast.downloadsToKeepValue;
    }];

    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    controller.delegate = self;
    [self.navigationController presentViewController:nav
                                            animated:YES
                                          completion:NULL];
}

- (BOOL)hasHitNotificationLimit {

    NSInteger currentCount = (NSInteger ) [SVPodcast MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"shouldNotify == YES AND isSubscribed == YES"]
                                                                           inContext:self.context];
    BOOL premium = [[SVSettings sharedInstance] premiumModeUnlocked];
    return !premium && currentCount >= [[SVSettings sharedInstance] maxFreeNotifications];
}

- (void)showNotificationsUpsell
{
    [Flurry logEvent:@"HitLimitUpsell"];
    NSString *title = NSLocalizedString(@"MAX_NOTIFICATIONS_UPDGRADE_PROMPT_TITLE", @"Title for the prompt asking the user to updgrade to premium");
    NSString *body = NSLocalizedString(@"HIT_MAX_NOTIFICATIONS_PROMPT_BODY", @"Body text prompting the user to upgrade to upgrade when they hit the free notifications limit" );
    BlockAlertView *signupAlert =  [BlockAlertView alertWithTitle:title
                                                          message:body];
    [signupAlert addButtonWithTitle:NSLocalizedString(@"LEARN_MORE", @"Find out more about a given option") block:^{
        [Flurry logEvent:@"LimitUpsellLearnMoreTapped"];
        UIViewController *controller = [[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController];
        [self presentViewController:controller animated:YES completion:nil];
    }];

    [signupAlert setCancelButtonWithTitle:NSLocalizedString(@"No, Thanks", @"No, Thanks") block:^{
        [Flurry logEvent:@"LimitUpsellDeclined"];
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
    if (shouldNotify && !self.podcast.isSubscribedValue) {
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
                                                     forFeedWithId:self.podcast.podstoreId
                                                      onCompletion:^{
                                                          [Flurry logEvent:@"ChangedNotificationSettingForFeed"
                                                                     withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:shouldNotify] forKey:@"ON"]];
                                                          DDLogInfo(@"Notifications setting changed successfully");
                                                          [self.context performBlock:^{
                                                              self.podcast.shouldNotifyValue = shouldNotify;
                                                          }];
                                                      }
                                                           onError:^(NSError *error) {
                                                               [Flurry logError:@"ChangedNotificationSettingForFeed" message:[error localizedDescription] error:error ];
                                                               DDLogError(@"Error when chanigng notification settings: %@", error);
                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                   BlockAlertView *alertView= [BlockAlertView alertWithTitle:[MessageGenerator randomErrorAlertTitle] message:@"There was a problem communicating with the Podster servers. Please try again later."];
                                                                   [alertView setCancelButtonWithTitle:@"OK" block:^{

                                                                   }];

                                                                   [alertView show];
                                                               });
                                                           }];

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
    DDLogInfo( @"Checking if notifications are enabled");
    if([[SVSettings sharedInstance] notificationsEnabled]){

        SVSettings *settings = [SVSettings sharedInstance];
        BOOL shouldAskAboutNotifications = [settings notificationsEnabled];

        if (shouldAskAboutNotifications) {
            void (^subscribeWithErrorAlertBlock)() = ^{
                if([self hasHitNotificationLimit]) {
                    [self showNotificationsUpsell];
                } else {
                    DDLogInfo( @"Creating notification subscription");
                    [[SVPodcatcherClient sharedInstance] changeNotificationSetting:YES
                                                                     forFeedWithId:self.podcast.podstoreId
                                                                      onCompletion:^{
                                                                          DDLogInfo( @"Succeed creating notification subscription");
                                                                          self.podcast.shouldNotifyValue = YES;
                                                                      }
                                                                           onError:^(NSError *error) {
                                                                               DDLogInfo( @"Failed creating notification subscription");
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
    [self.context performBlock:^void() {
        // Trigger the object itself to say it is subscribed
        [self.podcast subscribe];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureToolbar];
        });
        [self.context MR_saveNestedContexts];
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
        DDLogInfo( @"Creating a subscription for this podcast");
    });
    
    [Flurry logEvent:@"SubscribedToFeed"];
    
    void (^succeeded)() = ^{
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(YES);
            });

        }

    };

    [[SVPodcatcherClient sharedInstance] subscribeToFeedWithId:self.podcast.podstoreId
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
    [Flurry logEvent:@"UnsubscribedFromPodcast"];
    
    [self.context performBlock:^void() {
        [self.podcast unsubscribe];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self configureToolbar];
        });
    }];

    [[SVPodcatcherClient sharedInstance] unsubscribeFromFeedWithId:self.podcast.podstoreId
                                                      onCompletion:^{
                                                      } onError:^(NSError *error) {
    }];
}

- (IBAction)subscribeTapped:(id)sender {
    DDLogInfo( @"Subscribe tapped");
    if(!self.podcast.isSubscribedValue) {
        [self subscribeToPodcast];
    } else {
        [self unsubscribeFromPodcast];
    }

}

- (void)configureToolbar
{
    NSMutableArray *barItems = [NSMutableArray array];
    BOOL subscribed = self.podcast.isSubscribedValue;
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

- (void)loadFeedImage
{
    if ([self.podcast isKindOfClass:[SVPodcast class]]) {
        SVPodcast *coredataPodcast = (SVPodcast *)self.podcast;
        if (coredataPodcast.listImage) {
            UIImage *img = [UIImage imageWithData:coredataPodcast.listImage.imageData];
            self.imageView.image = img;
        } else {
            [imageView setImageWithURL:[NSURL URLWithString:self.podcast.thumbLogoURL] placeholderImage:imageView.image];
        }
    } else {
        [imageView setImageWithURL:[NSURL URLWithString:self.podcast.thumbLogoURL] placeholderImage:imageView.image];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{


    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
    [Flurry endTimedEvent:@"PodcastDetailsPageView"  withParameters:nil];
}

- (void)setupSubscribeButton
{
    [self.context performBlock:^{
        BOOL subscribed = self.podcast.isSubscribedValue;
        dispatch_async(dispatch_get_main_queue(), ^{
            if(subscribed) {
                self.subscribeButton.image = [UIImage imageNamed:@"heart-highlighted.png"];
            }


            self.subscribeButton.enabled = YES;
        });
    }];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }

}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)viewDidLoad
{
    DDLogInfo( @"%s", sel_getName(_cmd));
    [super viewDidLoad];
    isInitialLoad = YES;

    self.navigationItem.title = NSLocalizedString(@"Details", @"Details");

    self.tableView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    self.titleLabel.text = @"...";

    isLoading = YES;

    NSAssert(self.podcastId != nil, @"Should not be nil");
     BOOL blockHasSubscription = NO;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.podstoreId, self.podcastId];
    NSFetchRequest *request = [SVPodcast MR_requestFirstWithPredicate:predicate];
    [request setIncludesSubentities:YES];
    [request setRelationshipKeyPathsForPrefetching:@[SVPodcastRelationships.listImage]];

    self.podcast = [[self.context executeFetchRequest:request error:nil] lastObject];
    
    NSAssert(self.podcast.title != nil, @"There should be a title here");

    self.titleLabel.text = self.podcast.title;
    blockHasSubscription = self.podcast.isSubscribedValue;
    [self displayImageForPodcast];
    podcastLoaded = YES;
    [self configureUIForSubscriptionStatus:blockHasSubscription];
    [self displayEpisodesAndRefreshData];
}

- (void)displayImageForPodcast {
    // We had a local copy, so check for local image
    if (self.podcast.gridImage != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *image = [UIImage imageWithData:self.podcast.gridImage.imageData];
            self.imageView.image = image;
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            // We didn't have a local copy, so load from url
            [self.imageView setImageWithURL:[NSURL URLWithString:[self.podcast thumbLogoURL]]];
        });
    }
}

- (void)displayEpisodesAndRefreshData {
    NSAssert(self.podcast.title != nil, @"The podcast should be populated");
    NSAssert([NSThread isMainThread], @"This should only be on the main thread");
    self.descriptionLabel.text = self.podcast.summary;

    __weak SVPodcastDetailsViewController *blockSelf = self;

    void (^loadCompleteHandler)() = ^{
        if (blockSelf) {
            if ([gracePeriodTimer isValid]) {
                [gracePeriodTimer invalidate];
            }
            __strong SVPodcastDetailsViewController *strongSelf = blockSelf;

            strongSelf->isLoading = NO;
            DDLogInfo( @"Done loading entries");

            [strongSelf loadFeedImage];                        
        }
    };
    gracePeriodTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                        target:self
                                                      selector:@selector(gracePeriodTimerFired:)
                                                      userInfo:nil
                                                       repeats:NO];
    
    NSAssert(self.podcast != nil, @"Local Podcast should not be nil");
    [[SVSubscriptionManager sharedInstance] refreshPodcasts:@[self.podcast] complete:^{
       // [self reloadFetchedResultsController];
        loadCompleteHandler();
    }];
    
    [self reloadFetchedResultsController];

}

- (void)configureUIForSubscriptionStatus:(BOOL)isSubscribedValue {
    isSubscribed = isSubscribedValue;
    self.subscribeButton.enabled = NO;

    [self setupSubscribeButton];
}

- (void)gracePeriodTimerFired:(NSTimer *)timer
{



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
- (void)reloadFetchedResultsController
{

    if (!self.podcast) {
        return;
    }
    
    NSPredicate *itemsInPodcastPredicate = [NSPredicate predicateWithFormat:@"podcast = %@", self.podcast];
    DDLogVerbose(@"Reloading podcasts for podcast with core data identifier: %@", self.podcast.objectID);
    NSPredicate *predicate;

    if (self.podcast.hidePlayedEpisodesValue) {
        NSPredicate *notPlayedPredicate = [NSPredicate predicateWithFormat:@"%K = NO", SVPodcastEntryAttributes.played];

        predicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:itemsInPodcastPredicate, notPlayedPredicate,nil]];
    } else {
        predicate = itemsInPodcastPredicate;
    }

    NSFetchRequest *request = [SVPodcastEntry MR_requestAllSortedBy:SVPodcastEntryAttributes.datePublished
                                                          ascending:!self.podcast.sortNewestFirstValue
                                                      withPredicate:predicate
                                                          inContext:self.context];
    [request setIncludesPendingChanges:YES];
    NSAssert(self.context == [NSManagedObjectContext MR_defaultContext], @"Contexts should match");
    [request setIncludesSubentities:NO];
    [request setIncludesPendingChanges:YES];
    
    
    fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.context sectionNameKeyPath:nil cacheName:[NSString stringWithFormat:@"EpisodeListForId%@", self.podcast.podstoreId]];
    
    fetcher.delegate = self;
    DDLogVerbose(@"executing frc");
    NSError *error;
    if (![fetcher performFetch:&error]){
        DDLogError(@"Error refreshing data from core data: %@", error);
    }
    

    DDLogVerbose(@"Done with frc");
   [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self configureToolbar];
}


-(void)viewWillDisappear:(BOOL)animated
{
    if(observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        observer = nil;
    }
    fetcher.delegate = nil;
    fetcher = nil;
    [super viewWillDisappear:animated];

    if (updateOperationQueue.operationCount > 0) {
        DDLogVerbose(@"Podcast episode list will disappear. Cancelling update opreation");
        [updateOperationQueue cancelAllOperations];
    } else {
        DDLogVerbose(@"Podcast episode list will disappear, but there was nothing to cancel.");
    }

    NSAssert(self.podcast != nil, @"Local podcast should not be nil");

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadFetchedResultsController];
    [self.navigationController setToolbarHidden:NO animated:NO];
    [Flurry logEvent:@"PodcastDetailsPageView" timed:YES];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVPodcastEntry *episode = [fetcher objectAtIndexPath:indexPath];
    if (episode == [[SVPlaybackManager sharedInstance] currentEpisode]) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
        NSParameterAssert(controller);

        DDLogInfo(@"Navigating to player");
        [[self navigationController] pushViewController:controller animated:YES];
    } else {


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
                [[SVPlaybackManager sharedInstance] loadEpisode:episode
                                                        andPlay:YES];
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

    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
    SVEpisodeDetailsViewController *details = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"episodeDetails"];
    details.context = self.context;
    details.episode =[fetcher objectAtIndexPath:indexPath];
    NSAssert(details.episode, @"There should be an episode here");
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
    DDLogVerbose(@"Loading cell: %@", indexPath);
    SVPodcastEntry *episode= [[fetcher fetchedObjects] objectAtIndex:indexPath.row];

    [cell bind:episode];

    return cell;

}

#pragma mark - datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return fetcher.fetchedObjects.count;
}

- (IBAction)shareTapped:(id)sender {
    TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
    [tweet setInitialText:[NSString stringWithFormat:@"%@ (via @ItsPodster)", self.podcast.title]];
    [tweet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.podsterapp.com/feeds/%d", self.podcast.podstoreIdValue]]];

    // Show the controller
    [self presentViewController:tweet animated:YES completion:nil];

    // Called when the tweet dialog has been closed
    tweet.completionHandler = ^(TWTweetComposeViewControllerResult result)
    {
        // Dismiss the controller
        [self dismissViewControllerAnimated:YES completion:nil];
    };
}

- (IBAction)showDescriptionGestureRecognizerTapped:(id)sender {
    SVHtmlViewController *controller = [[SVHtmlViewController alloc] initWithNibName:nil bundle:nil];
    __block NSString *html;
    __block NSString *title;
    [self.context performBlockAndWait:^{
        html = self.podcast.summary;
        title = self.podcast.title;
    }];
    controller.html = html;
    controller.hidesBottomBarWhenPushed = YES;
    controller.title = title;
    [self.navigationController pushViewController:controller animated:YES];
}


#pragma mark - podcast settings delegate
- (void)podcastSettingsViewControllerShouldClose:(PodcastSettingsViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:NULL];

    self.podcast.sortNewestFirstValue = !controller.sortAscending;
    if (self.podcast.shouldNotifyValue != controller.shouldNotify) {
        [self updateNotificationSetting:controller.shouldNotify];
    }
    self.podcast.downloadsToKeepValue = controller.downloadsToKeep;
    [self reloadFetchedResultsController];
}

@end
