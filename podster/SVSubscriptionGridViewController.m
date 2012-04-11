//
//  SVSubscriptionGridViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionGridViewController.h"
#import "GMGridView.h"
#import "SVSubscriptionManager.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
#import "UILabel+VerticalAlign.h"
#import "PodcastGridCell.h"
#import "UIColor+Hex.h"
#import "PodsterManagedDocument.h"
#import "PodcastGridCellView.h"
@interface SVSubscriptionGridViewController()

@end

@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
}
@synthesize noContentLabel;
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
    [[PodsterManagedDocument sharedInstance] performWhenReady:^{                    
        [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];
    }];
    
    if (!fetcher) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
        NSFetchRequest *request = [SVPodcast MR_requestAllSortedBy:SVPodcastAttributes.nextItemDate ascending:NO withPredicate:predicate inContext:[PodsterManagedDocument defaultContext]];
        
        request.includesSubentities = NO;
        self.fetcher = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                           managedObjectContext:[PodsterManagedDocument defaultContext] 
                                                             sectionNameKeyPath:nil
                                                                      cacheName:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            

        NSError *error= nil;
            
            [self.fetcher performFetch:&error];
            NSAssert(error == nil, @"Error!");
            [self.gridView reloadData];
            self.noContentLabel.hidden = self.fetcher.fetchedObjects.count > 0;

        });
    }
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient.jpg"]];
    [self.view addSubview:image];
    [self.view sendSubviewToBack:image];
    self.gridView.backgroundColor = [UIColor clearColor];
    self.gridView.centerGrid = NO;
    
  }

- (void)viewDidUnload
{
    [self setNoContentLabel:nil];
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    LOG_GENERAL(2, @"ViewWillAppear");
    self.noContentLabel.text = NSLocalizedString(@"FAVORITES_NO_CONTENT", @"Message to show when the user hasn't added any favorites yet");
    self.noContentLabel.numberOfLines = 0;
    [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];


    [FlurryAnalytics logEvent:@"SubscriptionGridPageView" timed:YES];
  }

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [FlurryAnalytics endTimedEvent:@"SubscriptionGridPageView" withParameters:nil];
    self.fetcher.delegate = nil;
    [[SVSubscriptionManager sharedInstance] cancel];

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
        self.noContentLabel.hidden = self.fetcher.fetchedObjects.count > 0;
    
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{

        SVPodcast *podcast = [fetcher objectAtIndexPath:indexPath];
        LOG_GENERAL(2, @"GRID:Working with: %@", podcast.title);
        switch (type) {
            case NSFetchedResultsChangeInsert:

                LOG_GENERAL(2, @"GRID:Inserting object at %d", indexPath.row);
                [self.gridView insertObjectAtIndex:indexPath.row
                                     withAnimation:GMGridViewItemAnimationNone];
                break;
            case NSFetchedResultsChangeDelete:
                LOG_GENERAL(2, @"GRID:Removing object at %d", indexPath.row);
                [self.gridView removeObjectAtIndex:indexPath.row
                                     withAnimation:GMGridViewItemAnimationNone];
                break;
            case NSFetchedResultsChangeMove:
                LOG_GENERAL(2, @"GRID:Object should move from %d to %d", indexPath.row, newIndexPath.row );
                [self.gridView removeObjectAtIndex:indexPath.row
                                     withAnimation:GMGridViewItemAnimationNone];
                [self.gridView insertObjectAtIndex:newIndexPath.row
                                     withAnimation:GMGridViewItemAnimationNone];
//            needsReload = YES;
                break;
            case NSFetchedResultsChangeUpdate:
            {
                LOG_GENERAL(2, @"GRID: Refreshing item at %d", indexPath.row);
                [self.gridView reloadObjectAtIndex:indexPath.row
                                     withAnimation:GMGridViewItemAnimationNone];
            }
                break;
            default:
                LOG_GENERAL(2,@"GRID: Some other type of update");
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
    static UINib *podcastNib = nil;
    if (podcastNib == nil) {
      podcastNib = [UINib nibWithNibName:@"PodcastGridCellView" bundle:nil];   
    }
    SVPodcast *currentPodcast = (SVPodcast *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = (GMGridViewCell *)[gridView dequeueReusableCellWithIdentifier:@"MySubscriptionsGridCell"];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        cell.reuseIdentifier = @"MySubscriptionsGridCell";
        PodcastGridCellView *newCell = [[podcastNib instantiateWithOwner:nil options:nil] objectAtIndex:0]; 

        cell.contentView = newCell;


    } else {
           PodcastGridCellView *podcastCell =(PodcastGridCellView *) cell.contentView ;
        [podcastCell prepareForReuse];
    }
    
    PodcastGridCellView *podcastCell =(PodcastGridCellView *) cell.contentView ;
    [podcastCell bind:currentPodcast];

    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
        [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
