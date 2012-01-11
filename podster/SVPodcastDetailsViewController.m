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
#import "SVPodcatcherClient.h"
#import "UIAlertView+MKNetworkKitAdditions.h"
#import "SVPodcastEntry.h"
#import "SVPlaybackManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SVDownloadManager.h"
#import "SVPodcastSearchResult.h"

@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    MWFeedInfo *feedInfo;
    MWFeedParser *feedParser;
    MKNetworkOperation *op;
    NSManagedObjectContext *localContext;
    NSFetchedResultsController *fetcher;
    BOOL shouldSave;
    SVPodcast *localPodcast;
    
}
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize tableView = _tableView;
@synthesize metadataView;
@synthesize imageView;
@synthesize podcast = _podcast;

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

-(void)setPodcast:(SVPodcastSearchResult *)podcast
{
    NSParameterAssert(podcast);
    NSAssert(podcast.feedURL, @"The podcast did not have a feed url");
    _podcast = podcast;
}

-(SVPodcastSearchResult *)podcast
{
    return _podcast;
}

#pragma mark - View lifecycle
-(void)dealloc
{
    LOG_GENERAL(2, @"dealloc");
}
- (void)loadFeedImage
{
    [[SVPodcatcherClient sharedInstance] imageAtURL:[NSURL URLWithString:localPodcast.logoURL]
                                       onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {

                                           imageView.image = fetchedImage;
                                       }];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.metadataView.layer.shadowPath = CGPathCreateWithRect(self.metadataView.frame, NULL);
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    
    self.titleLabel.text = self.podcast.title;
    self.descriptionLabel.text = self.podcast.summary;
    [[SVPodcatcherClient sharedInstance] imageAtURL:[NSURL URLWithString:self.podcast.logoURL] onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
        self.imageView.image = fetchedImage;
    }];
    isLoading = YES;

    localContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    localContext.parentContext = [NSManagedObjectContext defaultContext];
    [localContext performBlockAndWait:^{
                    LOG_GENERAL(2, @"Lookuing up podcast in data store");
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.feedURL, self.podcast.feedURL];
        localPodcast = [SVPodcast findFirstWithPredicate:predicate
                                           inContext:localContext];
        LOG_GENERAL(2, @"Retrived: %@", localPodcast);
        if (!localPodcast) {
            LOG_GENERAL(2, @"Podcast didn't exist, creating it");
            localPodcast =[SVPodcast createInContext:localContext];
            localPodcast.title = self.podcast.title;
            localPodcast.summary = self.podcast.summary;
            localPodcast.logoURL = self.podcast.logoURL;
            localPodcast.feedURL = self.podcast.feedURL;
        }
    }];
    
    
    NSAssert([localContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:localPodcast] error:nil], @"Object should have id");
    __weak SVPodcastDetailsViewController *blockSelf = self;

    void (^loadCompleteHandler)() = ^{
        blockSelf->isLoading = NO;
        [self loadFeedImage];

        if (shouldSave) {
            LOG_GENERAL(2, @"Saving local context");
            [localContext performBlock:^void() {
                [localContext save];
            }];
        }

        LOG_GENERAL(2, @"Done loading entries");
    };

    op = [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcastWithFeedURL:localPodcast
                                                                          inContext:localContext
                                                                       onCompletion:loadCompleteHandler
                                                                            onError:^(NSError *error) {
                [UIAlertView showWithError:error];

            }];

    fetcher = [SVPodcastEntry fetchAllSortedBy:SVPodcastEntryAttributes.datePublished ascending:NO withPredicate:[NSPredicate predicateWithFormat:@"podcast.feedURL == %@", localPodcast.feedURL] groupBy:nil delegate:self inContext:localContext];
    [self.tableView reloadData];
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setTableView:nil];
    [self setMetadataView:nil];
    [self setImageView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillDisappear:(BOOL)animated
{
    if (op) {
        [op cancel];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
// Return YES for supported orientations
	return YES;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // NEed to save now
    __block SVPodcastEntry *entry = nil;
    [localContext performBlockAndWait:^{
        entry = [fetcher objectAtIndexPath:indexPath];
        [localContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:entry] error:nil];
        LOG_GENERAL(2, @"Saving local context");
        [localContext save];
        LOG_GENERAL(2, @"local context saved");
        NSManagedObjectContext *parent = [localContext parentContext];
        NSAssert(parent == [NSManagedObjectContext defaultContext], @"Parent shoudl be the main context");
        [parent performBlockAndWait:^{
            LOG_GENERAL(2, @"Saving parent context");
            [parent save];
            NSAssert(parent == [NSManagedObjectContext defaultContext], @"parent Context should be the default");
            LOG_GENERAL(2, @"Parent Context Saved");
        }];
    }];

    NSError *error;
    [fetcher performFetch:&error];
    NSAssert(error == nil, @"there should be no error");
    SVPodcastEntry *fetcherEpisode = [fetcher objectAtIndexPath:indexPath];
    [localContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:fetcherEpisode] error:nil];
    SVPodcastEntry *episode = (SVPodcastEntry *)[[NSManagedObjectContext defaultContext] existingObjectWithID:fetcherEpisode.objectID error:nil];
//    [[SVPlaybackManager sharedInstance] playEpisode:episode ofPodcast:podcast];
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
//    NSParameterAssert(controller);
//    [[self navigationController] pushViewController:controller animated:YES];
    NSLog(@"Selected episode %@", episode);
    
    [[SVDownloadManager sharedInstance] downloadEntry:episode];

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
        cell = [tableView dequeueReusableCellWithIdentifier:@"episodeCell"];
        SVPodcastEntry *episode= [fetcher objectAtIndexPath:indexPath];
        cell.textLabel.text = episode.title;
        cell.detailTextLabel.text = episode.summary;
    
    
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
