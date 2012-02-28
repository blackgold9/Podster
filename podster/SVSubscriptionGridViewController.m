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

@interface SVSubscriptionGridViewController()

@end

@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
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

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    self.fetcher.delegate = nil;
    self.fetcher = nil;
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

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
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
      self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-gunmetal.png"]];
    self.gridView.centerGrid = NO;
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
    [FlurryAnalytics logEvent:@"SubscriptionGridPageView" timed:YES];


    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription != nil"];
    NSFetchRequest *request = [SVPodcast requestAllSortedBy:@"lastUpdated" ascending:NO withPredicate:predicate];
    request.includesSubentities = NO;
    self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                       managedObjectContext:[NSManagedObjectContext defaultContext] 
                                                         sectionNameKeyPath:nil
                                                                  cacheName:nil];
    
    self.fetcher.delegate = self;

    NSError *error= nil;
    [self.fetcher performFetch:&error];
    NSAssert(error == nil, @"Error!");
    [self.gridView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
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
            PodcastGridCell *currentCell = (PodcastGridCell *)[self.gridView cellForItemAtIndex:indexPath.row];
            [currentCell bind:podcast fadeImage:YES];
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

-(GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    SVPodcast *currentPodcast = (SVPodcast *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    PodcastGridCell *cell = (PodcastGridCell *)[gridView dequeueReusableCellWithIdentifier:@"MySubscriptionsGridCell"];
    
    if (!cell) 
    {
        cell = [[PodcastGridCell alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    }
    
    [cell bind:currentPodcast fadeImage:YES];

    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
        [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
