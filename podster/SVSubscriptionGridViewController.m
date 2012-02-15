//
//  SVSubscriptionGridViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionGridViewController.h"
#import "GMGridView.h"
#import "SVSubscription.h"
#import "SVSubscriptionManager.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
#import "UILabel+VerticalAlign.h"
#import "PodcastGridCell.h"
#import "UIColor+Hex.h"
#import "GCDiscreetNotificationView.h"
@interface SVSubscriptionGridViewController()
- (void)configureCell:(GMGridViewCell *)cell 
           forPodcast:(SVPodcast *)currentPodcast
        fadingImage:(BOOL)updateImage;
@end
@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
    GCDiscreetNotificationView *notificationView;
}
@synthesize fetcher;
@synthesize gridView = _gridView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

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
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];
    if ([self.navigationController.parentViewController respondsToSelector:@selector(revealGesture:)] && [self.navigationController.parentViewController respondsToSelector:@selector(revealToggle:)])
	{
        
		// Check if we have a revealButton already.
		if (![self.navigationItem leftBarButtonItem])
		{
			// If not, allocate one and add it.
			UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reveal", @"Reveal") style:UIBarButtonItemStylePlain target:self.navigationController.parentViewController action:@selector(revealToggle:)];
            revealButton.image = [UIImage imageNamed:@"settings.png"];
			self.navigationItem.leftBarButtonItem = revealButton;
		}
	}
    if ([[SVSubscriptionManager sharedInstance] isBusy]) {
        [notificationView show:YES];
    }

   
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription != nil"];
    self.fetcher = [SVPodcast fetchAllSortedBy:@"lastUpdated" 
                                     ascending:NO
                                 withPredicate:predicate
                                       groupBy:nil
                                      delegate:self];
    
    self.fetcher.delegate = self;
    self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-gunmetal.png"]];
    notificationView = [[GCDiscreetNotificationView alloc] initWithText:@"Updating Podcasts" 
                                                           showActivity:YES 
                                                     inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom
                                                                 inView:self.view];


}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    LOG_GENERAL(2, @"ViewWillAppear");
    [[SVSubscriptionManager sharedInstance] addObserver:self
                                             forKeyPath:@"isBusy"
                                                options:NSKeyValueObservingOptionNew 
                                                context:nil];
    [FlurryAnalytics logEvent:@"SubscriptionGridPageView" timed:YES];


    NSAssert(self.fetcher, @"Fetcher should exist");
    self.fetcher.delegate = self;
    NSError *error= nil;
    [self.fetcher performFetch:&error];
    NSAssert(error == nil, @"Error!");
    [self.gridView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[SVSubscriptionManager sharedInstance] removeObserver:self
                                             forKeyPath:@"isBusy"
                                                ];

    [super viewWillDisappear:animated];
    [FlurryAnalytics endTimedEvent:@"SubscriptionGridPageView" withParameters:nil];
    self.fetcher.delegate = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma  mark - fetchedresults
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    LOG_GENERAL(2, @"Controller will changecontent");
    needsReload = NO;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    LOG_GENERAL(2, @"Controller done changing content");
    if (needsReload) {
        LOG_GENERAL(2, @"Needs reload");
        [self.gridView reloadData];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    SVPodcast *podcast = [self.fetcher objectAtIndexPath:indexPath];
    switch (type) {
        case NSFetchedResultsChangeInsert:
            LOG_GENERAL(2, @"GRID:Inserting object at %d", indexPath.row);
            [self.gridView insertObjectAtIndex:indexPath.row 
                                 withAnimation:GMGridViewItemAnimationScroll];
            break;
        case NSFetchedResultsChangeDelete:
            LOG_GENERAL(2, @"GRID:Removing object at %d", indexPath.row);
            [self.gridView removeObjectAtIndex:indexPath.row 
                                 withAnimation:GMGridViewItemAnimationScroll];
            break;
        case NSFetchedResultsChangeMove:
            LOG_GENERAL(2, @"GRID:Object should move from %d to %d", indexPath.row, newIndexPath.row );
            [self.gridView removeObjectAtIndex:indexPath.row 
                                 withAnimation:GMGridViewItemAnimationNone];
            [self.gridView insertObjectAtIndex:newIndexPath.row
                                 withAnimation:GMGridViewItemAnimationScroll];
           // needsReload = YES;
            break;
        case NSFetchedResultsChangeUpdate:
        {
            LOG_GENERAL(2, @"GRID: Refreshing item at %d", indexPath.row);
            GMGridViewCell *currentCell = [self.gridView cellForItemAtIndex:indexPath.row];
            [self configureCell:currentCell forPodcast:podcast fadingImage:NO];
        }
            break;
        default:
            break;
    }
    
}
-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    self.fetcher.delegate= nil;
    tappedIndex = position;
    SVPodcast *podcast =  [fetcher objectAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];

   SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];
    
    
    
}

#pragma mark - grid data
-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetcher] sections] objectAtIndex:0];
    LOG_GENERAL(2, @"Displaying %d podcats",  [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

-(CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return DEFAULT_GRID_CELL_SIZE;
}

- (void)configureCell:(GMGridViewCell *)cell 
           forPodcast:(SVPodcast *)currentPodcast
        fadingImage:(BOOL)fadeImage 
{
   
    UILabel *label = (UILabel *)[cell viewWithTag:1907];
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    label.text = currentPodcast.title;
    NSString *logoString = currentPodcast.smallLogoURL;
    if (!logoString) {
        logoString = currentPodcast.logoURL;
    }
    if(logoString) {
        NSURL *imageURL = [NSURL URLWithString: logoString];
        [imageView setImageWithURL:imageURL placeholderImage:nil shouldFade:fadeImage];
    } else {
        // Clear rhe image if there is no logo 
        imageView.image = nil; 
    }
    
    UILabel *countLabel = (UILabel *)[cell viewWithTag:1908];
    UIImageView *countOverlay = (UIImageView *)[cell viewWithTag:1909];
    if (currentPodcast.unseenEpsiodeCountValue > 0) {
        countOverlay.hidden = NO;
        countLabel.hidden = NO;
        countLabel.text = [NSString stringWithFormat:@"%d", currentPodcast.unseenEpsiodeCountValue];
    } else {
        countLabel.hidden = YES;
          countOverlay.hidden = YES;
    }
}

-(GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    SVPodcast *currentPodcast = (SVPodcast *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    PodcastGridCell *cell = (PodcastGridCell *)[gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[PodcastGridCell alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    }
    
    [cell bind:currentPodcast fadeImage:YES];

    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        if ([keyPath isEqualToString:@"isBusy"]){
            if([[SVSubscriptionManager sharedInstance] isBusy]) {
                [notificationView showAnimated]; 
            } else {
                [notificationView hideAnimated];
            }
        }
    });
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
