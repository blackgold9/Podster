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
#import "SVGPodderClient.h"
#import "UIAlertView+MKNetworkKitAdditions.h"
#import "SVPodcastEntry.h"
#import "SVPlaybackManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SVDownloadManager.h"

@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    MWFeedInfo *feedInfo;
    MWFeedParser *parser;
    MKNetworkOperation *op;
    
    
}
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize tableView = _tableView;
@synthesize metadataView;
@synthesize podcast;

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

#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.metadataView.layer.shadowPath = CGPathCreateWithRect(self.metadataView.frame, NULL);
    self.metadataView.layer.shadowOffset = CGSizeMake(0, 3);
    self.metadataView.layer.shadowOpacity = 0.5;
    
    self.titleLabel.text = self.podcast.title;
    self.descriptionLabel.text = self.podcast.summary;
    isLoading = YES;
    [self.tableView reloadData];
    op = [[SVGPodderClient sharedInstance] operationWithURLString:self.podcast.feedURL];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        parser = [[MWFeedParser alloc] initWithFeedData:[completedOperation responseData] textEncodingName:@"NSUnicodeStringEncoding"];
        parser.delegate = self;
   
        [parser parse];
    

    } onError:^(NSError *error) {
        [UIAlertView showWithError:error];
    }];
    [[SVGPodderClient sharedInstance] enqueueOperation:op];

    
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setTableView:nil];
    [self setMetadataView:nil];
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
    SVPodcastEntry *episode = [feedItems objectAtIndex:indexPath.row];
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
    if(isLoading) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"episodeCell"];
        SVPodcastEntry *episode= [feedItems objectAtIndex:indexPath.row];
        cell.textLabel.text = episode.title;
    }
    
    return cell;
    
}
    #pragma mark - datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return isLoading ? 1 : feedItems.count;
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    feedInfo = info;
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastEntryAttributes.guid, item.identifier];
        SVPodcastEntry *episode = [SVPodcastEntry findFirstWithPredicate:predicate
                                                               inContext:localContext];
        if (!episode) {
            episode = [SVPodcastEntry MR_createInContext:localContext];
        }
        
        episode.title = item.title;
        episode.summary = item.summary;
        episode.mediaURL = [item.enclosures.lastObject objectForKey:@"url"];
        episode.guid = item.identifier;
        episode.podcast = [self.podcast MR_inContext:localContext];
    }];
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    [UIAlertView showWithError:error];
}

-(void)feedParserDidStart:(MWFeedParser *)parser
{
    NSLog(@"Feed Parsing Started");
}

-(void)feedParserDidFinish:(MWFeedParser *)parser
{
    // We do this in the core data background block to get on the same queue that is creating the entries
    // That way we know we're done parsing before we reload data
    [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            feedItems = [NSMutableArray arrayWithArray: [SVPodcastEntry MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"podcast = %@", self.podcast]]];
            isLoading = NO;
            [self.tableView reloadData];  
        });
    }];
}
@end
